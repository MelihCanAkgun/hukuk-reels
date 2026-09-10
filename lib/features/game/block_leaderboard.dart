import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/social_bridge.dart';

const socialApiUrl = String.fromEnvironment('SOCIAL_API_URL',
    defaultValue: 'https://hukuk-games-social.hukuk-games-social.workers.dev');

class BlockLeaderboard extends StatefulWidget {
  const BlockLeaderboard({super.key});
  @override
  State<BlockLeaderboard> createState() => _BlockLeaderboardState();
}

class _BlockLeaderboardState extends State<BlockLeaderboard> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _message = TextEditingController();
  Map<String, dynamic> _data = {};
  String? _notice;
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
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
    _poll?.cancel();
    _name.dispose();
    _code.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final result = await socialCall('state');
    if (mounted) {
      setState(() {
        _data = result;
        if (result['error'] != null) _notice = result['error'] as String;
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
    final result = await socialCall(action, payload);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _notice = result['error'] as String? ?? result['message'] as String?;
      if (result['configured'] != null) _data = result;
      if (action == 'message' && result['ok'] == true) _message.clear();
    });
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
          const Text('Rekor sende mi?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
              'İki oyuncu, en yüksek skorlar. Lider değişince haberin olsun.',
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
                child: ListTile(
                  leading: Text(tied ? '=' : '${i + 1}',
                      style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFD76A))),
                  title: Text(
                      '${players[i]['name']}${players[i]['id'] == _data['me'] ? ' · Sen' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(players[i]['active'] == 1
                      ? 'En yüksek skor'
                      : 'Henüz katılmadı'),
                  trailing: Text('${players[i]['best']}',
                      style: const TextStyle(
                          fontSize: 23, fontWeight: FontWeight.w800)),
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
                'Diğer oyuncu rekorunu geçtiğinde telefonuna bildirim gelsin. iPhone’da uygulamayı ana ekrandan açıp izin ver.'),
            const SizedBox(height: 12),
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
              const Text('Diğer oyuncuya mesaj',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                  controller: _message,
                  maxLength: 180,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      hintText: 'Bir tur daha oynayalım mı?',
                      border: OutlineInputBorder())),
              if (_data['otherCanReceive'] != true)
                const Text(
                    'Mesaj göndermek için diğer oyuncunun bildirimleri açması gerekiyor.'),
              FilledButton.icon(
                  onPressed: _busy || _data['otherCanReceive'] != true
                      ? null
                      : () => _action('message', {'message': _message.text}),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Bildirim gönder')),
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
