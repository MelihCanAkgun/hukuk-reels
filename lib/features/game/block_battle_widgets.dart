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
    final myGame = mine?['game'] as Map?;
    final combo = (myGame?['combo'] as int?) ?? 0;
    final misses = (myGame?['misses'] as int?) ?? 0;
    final comboBonus = (myGame?['comboBonus'] as int?) ?? 0;
    final resetIn = (3 - misses).clamp(1, 3);

    String connection = '';
    if (session.pending) {
      connection = 'Hamle doğrulanıyor';
    } else if (!session.connected) {
      connection = 'Yeniden bağlanıyor…';
    } else if (session.players.any((p) => p['connected'] != true)) {
      connection = 'Rakibin bağlantısı bekleniyor · 15 sn';
    } else if (session.error != null) {
      connection = session.error!;
    } else if (combo > 0) {
      final bonus = comboBonus > 0 ? comboBonus : 10 * combo;
      connection = 'COMBO x$combo  ·  +$bonus COMBO  ·  RESET: $resetIn';
    }

    final displayText = feedback.isNotEmpty ? feedback : connection;
    final displayKey = feedback.isNotEmpty
        ? ValueKey('feedback-$feedback')
        : combo > 0
            ? ValueKey('combo-$combo-$resetIn')
            : ValueKey('connection-$connection');

    return SizedBox(
        height: 112,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                  width: 316,
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: _player(mine, other, 'SEN', isMine: true)),
                      if (other != null) ...[
                        SizedBox(
                            width: 50,
                            height: 50,
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
                        const SizedBox(width: 6),
                      ],
                      Expanded(child: _player(other, mine, 'RAKİP', isMine: false)),
                    ]),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: Text(displayText,
                            key: displayKey,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFD36A)))),
                  ])),
            )));
  }

  Widget _player(
      Map<String, dynamic>? p, Map<String, dynamic>? target, String label,
      {required bool isMine}) {
    final score = (p?['game']['score'] as int?) ?? 0;
    final attackCurrent = score % 500;
    final attackFactor = attackCurrent / 500.0;
    final targetLives = (target?['lives'] as int?) ?? 5;
    final showAttack = session.status != 'finished' && targetLives > 0;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(p?['name'] ?? label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
      Text('$score',
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.05,
              color: Colors.white)),
      const SizedBox(height: 2),
      BattleHearts(
          lives: p?['lives'] ?? 5,
          critical: p?['lives'] == 1 && session.status == 'playing'),
      const SizedBox(height: 2),
      if (showAttack) ...[
        Text(
          isMine ? 'ATTACK $attackCurrent / 500' : '$attackCurrent / 500',
          key: ValueKey(isMine ? 'battle-mine-attack' : 'battle-other-attack'),
          style: TextStyle(
            fontSize: isMine ? 8.5 : 8,
            fontWeight: FontWeight.w700,
            color: isMine ? const Color(0xFFFFD36A) : Colors.white54,
            letterSpacing: isMine ? 0.2 : 0,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            height: isMine ? 4 : 3,
            width: isMine ? 80 : 60,
            color: Colors.white12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: attackFactor,
                child: Container(
                  color: isMine
                      ? const Color(0xFFFFD36A)
                      : const Color(0xFFFF8B85),
                ),
              ),
            ),
          ),
        ),
      ] else ...[
        const SizedBox(height: 14),
      ],
    ]);
  }
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
              if (session.opponentRematchRequested &&
                  !session.rematchRequested) ...[
                const Text('Rakip tekrar oynamak istiyor!',
                    key: ValueKey('battle-opponent-rematch-notice'),
                    style: TextStyle(
                        color: Color(0xFFFFD36A),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 8),
              ],
              if (session.rematchRequested) ...[
                OutlinedButton.icon(
                  key: const ValueKey('battle-rematch-waiting-button'),
                  onPressed: null,
                  icon: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  label: const Text('Rakip bekleniyor…'),
                ),
              ] else ...[
                FilledButton.icon(
                  key: const ValueKey('battle-rematch-button'),
                  onPressed: () => session.requestRematch(),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(session.opponentRematchRequested
                      ? 'Kabul Et ve Tekrar Oyna'
                      : 'Tekrar Oyna'),
                ),
              ],
              if (session.error != null) ...[
                const SizedBox(height: 8),
                Text(session.error!,
                    key: const ValueKey('battle-result-error'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFFFF8B85),
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
              const SizedBox(height: 6),
              TextButton(onPressed: onClose, child: const Text('Lobiye dön')),
            ])),
      )),
    ));
  }
}
