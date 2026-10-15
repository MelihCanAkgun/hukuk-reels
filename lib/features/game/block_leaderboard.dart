import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/social_bridge.dart';
import '../../core/services/avatar_sync.dart';
import '../../core/services/avatar_bridge.dart';
import '../profile/profile_avatar.dart';

const socialApiUrl = String.fromEnvironment('SOCIAL_API_URL',
    defaultValue: 'https://hukuk-games-social.hukuk-games-social.workers.dev');

class BlockLeaderboard extends StatefulWidget {
  const BlockLeaderboard({super.key});
  @override
  State<BlockLeaderboard> createState() => _BlockLeaderboardState();
}

class _BlockLeaderboardState extends State<BlockLeaderboard>
    with WidgetsBindingObserver {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _message = TextEditingController();
  Map<String, dynamic> _data = {};
  String? _notice;
  bool _busy = false;
  final Set<String> _fullCached = {};
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_busy &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _refresh();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _name.dispose();
    _code.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _refresh();
  }

  Future<void> _refresh() async {
    final result = await AvatarSync.instance.sync(await socialCall('state'));
    if (mounted) {
      setState(() {
        _data = result;
        _notice = result['error'] as String?;
      });
    }
  }

  Future<void> _action(String action,
      [Map<String, dynamic> payload = const {}]) async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    // Do not insert an await here: Safari requires the permission call inside the tap.
    var result = await socialCall(action, payload);
    if (action == 'leave') AvatarSync.instance.clearPeers();
    if (action == 'join' && result['error'] == null) {
      result = await AvatarSync.instance.sync(result);
    }
    if (!mounted) return;
    if (action == 'message') await _refresh();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _notice = result['error'] as String? ?? result['message'] as String?;
      if (result['configured'] != null) _data = result;
      if (action == 'message' && result['ok'] == true) _message.clear();
    });
  }

  String? get _deliveryNotice {
    final event = _data['lastNotification'];
    if (event is! Map) return null;
    final status = event['delivery_status'];
    if (status == 'accepted') {
      return 'Son bildirim cihazın bildirim servisine iletildi. Telefonda görünmesi izinlere ve Odak ayarlarına bağlı.';
    }
    if (status == 'partial') {
      return 'Son bildirim bazı cihazlara iletildi; diğerleri yeniden denenecek.';
    }
    if (status == 'no_device' || status == 'http_404' || status == 'http_410') {
      return 'Son bildirim iletilemedi: alıcının bildirimleri yeniden açması gerekiyor.';
    }
    final created = event['created'];
    final expired = created is num &&
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - created >= 3600;
    if (expired || (event['attempts'] as num? ?? 0) >= 4) {
      return 'Son bildirimin gönderimi tamamlanamadı. Yeni bir bildirim gönderebilirsin.';
    }
    if (status == 'timeout' ||
        status == 'send_error' ||
        (status is String && status.startsWith('http_'))) {
      return 'Bildirim servisine iletilemedi; sunucu yeniden deneyecek.';
    }
    return 'Son bildirim gönderim sırasında; henüz teslim onayı yok.';
  }

  /// Yalnız Oyuncu 1'e görünür: uygulamaya yüklenen profil fotoğraflarını
  /// cihaza indirir. Fotoğraflar eşitlemeyle zaten bellekte; ağ isteği yok.
  Widget _avatarDownloads() {
    final sync = AvatarSync.instance;
    return ValueListenableBuilder<int>(
      valueListenable: sync.changes,
      builder: (context, _, __) {
        final rows = <Widget>[];
        for (final p
            in (_data['players'] as List? ?? const []).whereType<Map>()) {
          final id = p['id'];
          if (id is! int) continue;
          final Uint8List? bytes = id == _data['me']
              ? ProgressService.instance.avatar
              : sync.photoOf(id);
          final name = (p['name'] as String?) ?? 'Oyuncu $id';
          rows.add(ListTile(
            contentPadding: EdgeInsets.zero,
            leading: id == _data['me']
                ? const ProfileAvatar(size: 48)
                : PeerAvatar(id: id, name: name, size: 48),
            title: Text(name),
            subtitle: Text(bytes == null
                ? 'Fotoğraf yüklenmemiş'
                : p['avatarFull'] is int
                    ? 'Tam kalite · ${p['avatarWidth']}×${p['avatarHeight']} · '
                        '${((p['avatarFull'] as int) / 1048576).toStringAsFixed(1)} MB'
                    : 'Yalnız küçük kopya (320×320)'),
            trailing: IconButton(
              tooltip: 'Fotoğrafı indir',
              icon: const Icon(Icons.download_rounded),
              onPressed: bytes == null
                  ? null
                  : () => _downloadAvatar(bytes, name, p['avatar'] as String?,
                      fullId: p['avatarFull'] is int ? id : null),
            ),
          ));
        }
        if (rows.isEmpty) return const Text('Henüz oyuncu bilgisi yok.');
        return Column(children: rows);
      },
    );
  }

  Future<void> _downloadAvatar(Uint8List bytes, String name, String? version,
      {int? fullId}) async {
    // Dosya adı ASCII kalsın; Türkçe karakterler bazı cihazlarda bozuluyor.
    const tr = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'Ç': 'C',
      'Ğ': 'G',
      'İ': 'I',
      'Ö': 'O',
      'Ş': 'S',
      'Ü': 'U'
    };
    final safe = name
        .split('')
        .map((c) => tr[c] ?? c)
        .join()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final file = 'profil_${safe.isEmpty ? 'oyuncu' : safe}'
        '${version == null ? '' : '_${version.substring(0, version.length.clamp(0, 8))}'}.jpg';
    final String result;
    if (fullId != null) {
      // Tam kalite kopya sunucudan (yalnız Oyuncu 1) indirilir; bellekte
      // tutulur, ikinci dokunuş anında kaydeder.
      if (!_fullCached.contains('$fullId:$version')) {
        setState(() => _notice = 'Tam kalite fotoğraf indiriliyor…');
      }
      final r = await socialCall('avatarSaveFull',
          {'id': fullId, 'version': version, 'filename': file});
      final error = r['error'] as String?;
      result = error != null ? 'error:$error' : (r['status'] as String? ?? '');
      if (error == null) _fullCached.add('$fullId:$version');
    } else {
      result = await saveAvatarJpeg(base64Encode(bytes), file);
    }
    if (!mounted) return;
    if (result == 'retry') {
      // İndirme sürerken iPhone dokunuş iznini düşürür; ikinci dokunuş kaydeder.
      setState(() => _notice = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Fotoğraf hazır.'),
        duration: const Duration(seconds: 12),
        action: SnackBarAction(
            label: 'Kaydet',
            onPressed: () =>
                _downloadAvatar(bytes, name, version, fullId: fullId)),
      ));
      return;
    }
    if (result.isEmpty) {
      setState(() => _notice = null);
      return;
    }
    setState(() => _notice = result.startsWith('error:')
        ? result.substring(6)
        : result == 'shared'
            ? 'Fotoğraf paylaşım menüsüne gönderildi.'
            : 'Fotoğraf indirildi: $file');
  }

  @override
  Widget build(BuildContext context) {
    final connected = _data['connected'] == true;
    final configured = _data['configured'] == true;
    final players = (_data['players'] as List?) ?? [];
    final tied =
        players.length == 2 && players[0]['best'] == players[1]['best'];
    return Scaffold(
      backgroundColor: const Color(0xFF142442),
      appBar: AppBar(
          title: const Text('İkimizin sıralaması'),
          backgroundColor: const Color(0xFF142442)),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Icon(Icons.emoji_events_rounded,
              color: Color(0xFFFFD76A), size: 52),
          const SizedBox(height: 12),
          const Text('Lider Tablosu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('İyi olan kazansın bir tanem 😘',
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (_data.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (!configured)
            Text(_data['native'] == true
                ? 'İki kişilik sıralama ve bildirimler şu anda ana ekrana yüklenen web uygulamasında kullanılabilir.'
                : 'İki kişilik servis hazırlanıyor. Oyunlarını oynamaya devam edebilirsin.'),
          if (configured && !connected) ...[
            TextField(
                controller: _name,
                maxLength: 24,
                decoration: const InputDecoration(
                    labelText: 'Oyuncu adın', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _code,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                    labelText: 'Sana ait oyuncu kodu',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const Text(
                'Kodun hesabının anahtarıdır. Yalnızca sana ait kodu kullan. Bu cihazdaki rekorun sıralamaya eklenecek.'),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _busy
                    ? null
                    : () => _action('join', {
                          'name': _name.text,
                          'token': _code.text,
                          'score': ProgressService.instance.blockHigh,
                        }),
                child: const Text('Sıralamaya katıl')),
          ],
          if (connected) ...[
            for (var i = 0; i < players.length; i++)
              Card(
                color: players[i]['id'] == _data['me']
                    ? const Color(0xFF294573)
                    : const Color(0xFF203252),
                // ListTile öndeki öğeyi ~48 px'e sıkıştırdığı için kendi düzenimiz.
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 18, 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(tied ? '=' : '${i + 1}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFD76A))),
                      ),
                      const SizedBox(width: 10),
                      players[i]['id'] == _data['me']
                          ? const ProfileAvatar(size: 68)
                          : PeerAvatar(
                              id: players[i]['id'] as int,
                              name: players[i]['name'] as String?,
                              size: 68),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${players[i]['name']}${players[i]['id'] == _data['me'] ? ' · Sen' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                                players[i]['active'] == 1
                                    ? 'En yüksek skor'
                                    : 'Henüz katılmadı',
                                style: const TextStyle(
                                    color: Color(0xFFD5DEEE), fontSize: 13.5)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${players[i]['best']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            if (_data['pending'] == true)
              const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                      'Yeni rekorun gönderiliyor; bağlantı yoksa cihazında saklanır.')),
            TextButton.icon(
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Sıralamayı yenile')),
            const Divider(height: 32),
            const Text('Bildirimler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
                'Diğer oyuncu rekorunu geçtiğinde telefonuna bildirim gelsin. iPhone’da uygulamayı ana ekrandan açıp izin ver. (yerse)'),
            const SizedBox(height: 12),
            Text(_data['subscribed'] == true
                ? 'Bu cihazın bildirim kaydı aktif.'
                : _data['permission'] == 'granted'
                    ? 'İzin açık; bildirim cihazı kaydı tamamlanmalı.'
                    : 'Bu cihazda bildirimler henüz açık değil.'),
            if (_data['pushError'] != null) Text(_data['pushError'] as String),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _action(_data['subscribed'] == true
                      ? 'unsubscribe'
                      : 'subscribe'),
              icon: Icon(_data['subscribed'] == true
                  ? Icons.notifications_active
                  : Icons.notifications_outlined),
              label: Text(_data['subscribed'] == true
                  ? 'Bildirimleri kapat'
                  : 'Bildirimleri aç'),
            ),
            if (_data['me'] == 1) ...[
              const Divider(height: 32),
              const Text('ariciğime bildirim gönderme paneli: ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                  controller: _message,
                  maxLength: 180,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      hintText: '', border: OutlineInputBorder())),
              Text(_data['error'] != null
                  ? 'Alıcının bildirim durumu güncellenemedi.'
                  : _data['otherCanReceive'] == true
                      ? 'Alıcı: ${_data['otherRegisteredDevices'] ?? 1} bildirim cihazı kayıtlı.'
                      : 'Alıcı: kayıtlı bildirim cihazı yok.'),
              if (_deliveryNotice != null) ...[
                const SizedBox(height: 8),
                Text(_deliveryNotice!),
              ],
              TextButton.icon(
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(Icons.sync),
                  label: const Text('Alıcı durumunu kontrol et')),
              if (_data['otherCanReceive'] != true)
                const Text(
                    'Mesaj göndermek için diğer oyuncunun bildirimleri açması gerekiyor.'),
              FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _action('message', {'message': _message.text}),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Bildirim gönder')),
              const Divider(height: 32),
              const Text('Profil fotoğrafları',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _avatarDownloads(),
            ],
            const SizedBox(height: 16),
            TextButton(
                onPressed: _busy ? null : () => _action('leave'),
                child: const Text('Bu cihazdaki oyuncu bağlantısını kaldır')),
          ],
          if (_busy) const LinearProgressIndicator(),
          if (_notice != null)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Semantics(liveRegion: true, child: Text(_notice!))),
        ]),
      ))),
    );
  }
}
