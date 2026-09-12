import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/social_bridge.dart';
import 'block_leaderboard.dart';
import 'block_battle_session.dart';
import 'block_blast_screen.dart';

class BlockBattleLobby extends StatefulWidget {
  const BlockBattleLobby({super.key});
  @override
  State<BlockBattleLobby> createState() => _BlockBattleLobbyState();
}

class _BlockBattleLobbyState extends State<BlockBattleLobby> {
  late final BlockBattleSession _session;
  final _code = TextEditingController();
  bool _registered = false, _busy = true, _inGame = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _session = BlockBattleSession()..addListener(_changed);
    unawaited(_init());
  }

  Future<void> _init() async {
    await socialCall('init', {'url': socialApiUrl});
    final profile = await socialCall('state');
    if (!mounted) return;
    setState(() {
      _registered = profile['connected'] == true && profile['me'] != null;
      _busy = false;
    });
    if (_registered) await _session.action('resume');
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    if (!_inGame &&
        _session.mine != null &&
        ['countdown', 'playing', 'finished'].contains(_session.status)) {
      _inGame = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => BlockBlastScreen(battle: _session)));
        if (mounted) setState(() => _inGame = false);
      });
    }
  }

  Future<void> _action(String action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await _session.action(action, {'room': _code.text});
    if (mounted) {
      setState(() {
        _busy = false;
        if (!ok) _error = _session.error;
      });
    }
  }

  @override
  void dispose() {
    _session.removeListener(_changed);
    _session.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF182B50),
        appBar: AppBar(
            title: const Text('1v1 Battle'),
            backgroundColor: const Color(0xFF182B50)),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const Icon(Icons.sports_mma_rounded,
                size: 48, color: Color(0xFFFFD36A)),
            const SizedBox(height: 16),
            const Text('Aynı parçalar. İki tahta. Beş can.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
                'Her 600 toplam puanda rakibinden bir can al. Hamlen kalmazsa bir can kaybedersin; tahta yenilenir, puanın kalır.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (!kIsWeb)
              const Text(
                  'Battle modu yayınlanan web / ana ekran uygulamasında kullanılabilir.')
            else if (!_registered) ...[
              const Text('Önce mevcut oyuncu kodunla lider tablosuna bağlan.'),
              FilledButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const BlockLeaderboard()));
                    if (mounted) await _init();
                  },
                  child: const Text('Oyuncu bağlantısını aç')),
            ] else if (_session.room == null) ...[
              FilledButton.icon(
                  onPressed: _busy ? null : () => _action('create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Oda oluştur')),
              const SizedBox(height: 20),
              TextField(
                  controller: _code,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z2-9]'))
                  ],
                  decoration: const InputDecoration(
                      labelText: 'Oda kodu', border: OutlineInputBorder())),
              OutlinedButton(
                  onPressed: _busy ? null : () => _action('join'),
                  child: const Text('Odaya katıl')),
            ] else ...[
              SelectableText(_session.room!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 34,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w900)),
              TextButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: _session.room!)),
                  icon: const Icon(Icons.copy),
                  label: const Text('Oda kodunu kopyala')),
              for (final p in _session.players)
                ListTile(
                    leading: Icon(
                        p['connected'] == true
                            ? Icons.circle
                            : Icons.circle_outlined,
                        size: 14,
                        color: Colors.tealAccent),
                    title: Text(p['name']),
                    trailing: Text(p['ready'] == true ? 'Hazır' : 'Bekliyor')),
              if (_session.players.length < 2)
                const Text(
                    'Oda kodunu diğer oyuncuya ver. İkiniz de hazır olduğunuzda maç başlayacak.'),
              FilledButton(
                  onPressed:
                      _session.connected && _session.mine?['ready'] != true
                          ? () => _action('ready')
                          : null,
                  child: Text(_session.mine?['ready'] == true
                      ? 'Rakip bekleniyor…'
                      : 'Hazırım')),
              TextButton(
                  onPressed: () async {
                    if (_session.connected) await _session.action('resign');
                    await _session.action('leave');
                  },
                  child: const Text('Odadan ayrıl')),
            ],
            if (_busy) const LinearProgressIndicator(),
            if ((_error ?? _session.error) != null)
              Text(_error ?? _session.error!,
                  style: const TextStyle(color: Colors.amber)),
          ]),
        ))),
      );
}
