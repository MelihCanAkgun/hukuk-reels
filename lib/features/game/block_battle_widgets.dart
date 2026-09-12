import 'dart:math';
import 'package:flutter/material.dart';
import 'block_battle_session.dart';
import 'block_battle_life_fx.dart';

class BattleHud extends StatelessWidget {
  final BlockBattleSession session;
  final List<Color> palette;
  final String feedback;
  const BattleHud(
      {super.key,
      required this.session,
      required this.palette,
      required this.feedback});
  @override
  Widget build(BuildContext context) {
    final mine = session.mine, other = session.opponent;
    String connection =
        session.pending ? 'Hamle doğrulanıyor' : 'Her 600 puan = rakibe −1 can';
    if (!session.connected) {
      connection = 'Yeniden bağlanıyor…';
    } else if (session.players.any((p) => p['connected'] != true)) {
      connection = 'Rakibin bağlantısı bekleniyor · 15 sn';
    }
    if (session.error != null) connection = session.error!;
    return SizedBox(
        height: 112,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                  width: 310,
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: _player(mine, 'SEN')),
                      if (other != null) ...[
                        SizedBox(
                            width: 52,
                            height: 52,
                            child: RepaintBoundary(
                                child: CustomPaint(
                                    key:
                                        const ValueKey('battle-opponent-board'),
                                    painter: BattlePreviewPainter(
                                        (other['game']['grid'] as List)
                                            .map(
                                                (r) => (r as List).cast<int?>())
                                            .toList(),
                                        palette)))),
                        const SizedBox(width: 8),
                      ],
                      Expanded(child: _player(other, 'RAKİP')),
                    ]),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: Text(feedback.isNotEmpty ? feedback : connection,
                            key: ValueKey(feedback),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFFFFD36A)))),
                  ])),
            )));
  }

  Widget _player(Map<String, dynamic>? p, String label) => Column(children: [
        Text(p?['name'] ?? label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Text('${p?['game']['score'] ?? 0}',
            style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        BattleHearts(
            lives: p?['lives'] ?? 5,
            critical: p?['lives'] == 1 && session.status == 'playing'),
      ]);
}

class BattlePreviewPainter extends CustomPainter {
  final List<List<int?>> board;
  final List<Color> palette;
  BattlePreviewPainter(this.board, this.palette);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final cell = min(size.width, size.height) / 8;
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        paint.color = board[r][c] == null
            ? const Color(0xFF101F3B)
            : palette[board[r][c]!];
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(c * cell, r * cell, cell - 1, cell - 1),
                const Radius.circular(1)),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(BattlePreviewPainter old) {
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (board[r][c] != old.board[r][c]) return true;
      }
    }
    return false;
  }
}

class BattleResult extends StatelessWidget {
  final BlockBattleSession session;
  final VoidCallback onClose;
  const BattleResult({super.key, required this.session, required this.onClose});
  @override
  Widget build(BuildContext context) {
    final state = session.state!;
    final win = state['winner'] == session.me;
    final winner =
        session.players.where((p) => p['id'] == state['winner']).firstOrNull;
    final duration = state['startAt'] is int
        ? max(
            0,
            ((state['endedAt'] as int? ?? session.now) -
                    (state['startAt'] as int)) ~/
                1000)
        : 0;
    final reason = switch (state['reason']) {
      'board_out' => 'Tahtada hamle kalmadı.',
      'score' => 'Skor hasarı son canı aldı.',
      'disconnect' => 'Bağlantı süresi doldu.',
      'resigned' => 'Bir oyuncu maçtan ayrıldı.',
      _ => 'Odanın süresi doldu.',
    };
    return Positioned.fill(
        child: ColoredBox(
      color: const Color(0xEF101C35),
      child: Center(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(win ? Icons.emoji_events_rounded : Icons.flag_rounded,
                  size: 52, color: const Color(0xFFFFD36A)),
              Text(
                  winner == null
                      ? 'MAÇ BİTTİ'
                      : win
                          ? 'VICTORY'
                          : 'DEFEAT',
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              if (winner != null)
                Text('Kazanan: ${winner['name']}', textAlign: TextAlign.center),
              Text(reason, textAlign: TextAlign.center),
              Text(
                  'Maç süresi: ${duration ~/ 60}:${(duration % 60).toString().padLeft(2, '0')}'),
              const SizedBox(height: 18),
              for (final p in session.players)
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(children: [
                          Text('${p['name']} · ${p['game']['score']} puan',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                              '${p['lives']} can · ${p['boardOuts']} kez hamlesiz'),
                          Text('Rakibe verilen skor hasarı: ${p['damage']}'),
                        ]))),
              const SizedBox(height: 16),
              FilledButton(onPressed: onClose, child: const Text('Lobiye dön')),
            ])),
      )),
    ));
  }
}
