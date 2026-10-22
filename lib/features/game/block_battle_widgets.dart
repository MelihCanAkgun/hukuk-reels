import 'dart:math';
import 'package:flutter/material.dart';
import 'block_battle_session.dart';
import 'block_blast_engine.dart';
import 'block_battle_life_fx.dart';
import 'block_board_fx.dart';
import 'block_battle_jokers.dart';
import '../../core/widgets/pixel_logo.dart';
import 'combo_hud.dart';

class BattleHud extends StatelessWidget {
  final BlockBattleSession session;
  final List<Color> palette;
  final String feedback;

  /// 1v1 joker düğmesi (kendi skorunun yanında) ve rakip tahtasının anahtarı
  /// (dondurma atışının hedefi).
  final Widget? joker;
  final GlobalKey? opponentBoardKey;
  const BattleHud(
      {super.key,
      required this.session,
      required this.palette,
      required this.feedback,
      this.joker,
      this.opponentBoardKey});
  @override
  Widget build(BuildContext context) {
    final mine = session.mine, others = session.opponents;
    final myGame = mine?['game'] as Map?;
    final combo = (myGame?['combo'] as int?) ?? 0;
    final misses = (myGame?['misses'] as int?) ?? 0;
    final comboBonus = (myGame?['comboBonus'] as int?) ?? 0;

    final waiting = session.players
        .where((p) => p['out'] != true && p['connected'] != true)
        .toList();
    String connection = '';
    if (session.pending) {
      connection = 'Hamle doğrulanıyor';
    } else if (!session.connected) {
      connection = 'Yeniden bağlanıyor…';
    } else if (waiting.isNotEmpty) {
      connection = session.trio
          ? '${waiting.first['name']} bekleniyor · 15 sn'
          : 'Rakibin bağlantısı bekleniyor · 15 sn';
    } else if (session.eliminated && session.status == 'playing') {
      connection = 'ELENDİN · ${mine?['place'] ?? 3}. sıra · maç sürüyor';
    } else if (session.error != null) {
      connection = session.error!;
    }

    final displayText = feedback.isNotEmpty ? feedback : connection;
    final displayKey = feedback.isNotEmpty
        ? ValueKey('feedback-$feedback')
        : ValueKey('connection-$connection');
    final anyAlive = others.any((p) => p['out'] != true);

    return SizedBox(
        height: 112,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                  width: 350,
                  child: Column(children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                              child: _me(mine,
                                  attack: anyAlive && !session.eliminated)),
                          if (joker != null) ...[
                            const SizedBox(width: 6),
                            joker!,
                          ],
                          for (var i = 0; i < others.length; i++) ...[
                            const SizedBox(width: 6),
                            _opponent(others[i], i,
                                width: session.trio
                                    ? 116
                                    : joker == null
                                        ? 168
                                        : 140),
                          ],
                        ]),
                    const SizedBox(height: 3),
                    ComboHud(
                      combo: combo,
                      misses: misses,
                      comboBonus: comboBonus,
                    ),
                    if (displayText.isNotEmpty)
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

  /// Bir sonraki 500 puan eşiğine (rakiplere hasar) kalan.
  Widget _attack(int score, {required bool mine, Key? key}) {
    final current = score % 500;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('${500 - current} PUAN KALDI',
          key: key,
          style: TextStyle(
            fontSize: mine ? 8.5 : 7.5,
            fontWeight: FontWeight.w700,
            color: mine ? const Color(0xFFFFD36A) : Colors.white54,
            height: 1.0,
          )),
      const SizedBox(height: 2),
      Container(
        height: mine ? 4 : 3,
        width: mine ? 84 : 58,
        color: Colors.white12,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: current / 500,
          child: Container(
              color: mine ? const Color(0xFFFFD36A) : const Color(0xFFFF8B85)),
        ),
      ),
    ]);
  }

  Widget _me(Map<String, dynamic>? p, {required bool attack}) {
    final score = (p?['game']['score'] as int?) ?? 0;
    final live = session.status != 'finished';
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(p?['name'] ?? 'SEN',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFD36A))),
      Text('$score',
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.05,
              color: Colors.white)),
      const SizedBox(height: 2),
      BattleHearts(
          lives: p?['lives'] ?? 5,
          critical: p?['lives'] == 1 && session.status == 'playing'),
      const SizedBox(height: 2),
      if (attack && live)
        _attack(score, mine: true, key: const ValueKey('battle-mine-attack'))
      else
        const SizedBox(height: 14),
    ]);
  }

  /// Rakip kartı: küçük tahta, ad, puan, canlar. Elenen rakip kararır.
  Widget _opponent(Map<String, dynamic> p, int index, {required double width}) {
    final out = p['out'] == true;
    final frozen = session.frozen(p);
    final jokers = session.jokersOf(p);
    final score = (p['game']['score'] as int?) ?? 0;
    final board = session.trio ? 52.0 : 60.0;
    final grid = (p['game']['grid'] as List)
        .map((r) => (r as List).cast<int?>())
        .toList();
    return Container(
      key: ValueKey('battle-opponent-${p['id']}'),
      width: width,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF101F3B),
        border: Border.all(
            color: out ? const Color(0xFF26324A) : const Color(0xFF3A5C92),
            width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF070F1E), offset: Offset(0, 3)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Flexible(
            child: Text(p['name'] ?? 'RAKİP',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: out ? Colors.white38 : Colors.white70)),
          ),
          // Rakibin jokerleri; kullandıkları soluk.
          for (final joker in jokers) ...[
            const SizedBox(width: 3),
            JokerSprite(joker,
                key: ValueKey('battle-opponent-joker-${p['id']}-$joker'),
                size: 12,
                dim: session.jokerUsed(p, joker)),
          ],
        ]),
        const SizedBox(height: 3),
        Row(children: [
          SizedBox(
            key: opponentBoardKey,
            width: board,
            height: board,
            child: Stack(fit: StackFit.expand, children: [
              RepaintBoundary(
                  child: CustomPaint(
                      key: session.trio
                          ? ValueKey('battle-opponent-board-${p['id']}')
                          : const ValueKey('battle-opponent-board'),
                      painter: BattlePreviewPainter(grid, palette))),
              if (frozen)
                ColoredBox(
                  key: ValueKey('battle-opponent-frozen-${p['id']}'),
                  color: const Color(0x887FC4FF),
                  child: Center(child: PixelLogo(kSnowflake, size: 26)),
                ),
              if (out)
                ColoredBox(
                  color: const Color(0xC0070F1E),
                  child: Center(
                    child: Text('ELENDİ\n${p['place'] ?? ''}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 9,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF8B85))),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Opacity(
              opacity: out ? .5 : 1,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('$score',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 12,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: BattleHearts(
                            lives: p['lives'] ?? 5,
                            critical:
                                p['lives'] == 1 && session.status == 'playing'),
                      ),
                    ),
                    if (!out && session.status != 'finished') ...[
                      const SizedBox(height: 5),
                      // Bir sonraki hasar eşiğine ilerleme.
                      Container(
                        key: index == 0
                            ? const ValueKey('battle-other-attack')
                            : null,
                        height: 3,
                        color: Colors.white12,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: score % 500 / 500,
                          child: Container(color: const Color(0xFFFF8B85)),
                        ),
                      ),
                    ],
                  ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

/// Üçlü maçta elenen oyuncu maç bitene kadar kalan oyuncuların tahtalarını
/// yan yana izler; altta elendiği yazar.
class BattleSpectator extends StatelessWidget {
  final BlockBattleSession session;
  final List<Color> palette;
  const BattleSpectator(
      {super.key, required this.session, required this.palette});

  @override
  Widget build(BuildContext context) {
    final others = session.opponents;
    final place = session.mine?['place'];
    return LayoutBuilder(builder: (context, c) {
      final board = min(
              (c.maxWidth - 24 - 12 * (others.length - 1)) /
                  max(1, others.length),
              c.maxHeight - 190)
          .clamp(80.0, 340.0);
      return Column(
        key: const ValueKey('battle-spectator'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('İZLİYORSUN',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white54)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < others.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                _board(others[i], board),
              ],
            ],
          ),
          const SizedBox(height: 22),
          Container(
            key: const ValueKey('battle-eliminated-banner'),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF3A1622),
              border: Border.all(color: const Color(0xFFFF8B85), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0xFF070F1E), offset: Offset(0, 4)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('ELENDİN${place == null ? '' : ' · $place. SIRA'}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xFFFF8B85))),
              const SizedBox(height: 2),
              const Text('Maç bitince sonuç gelecek',
                  style: TextStyle(fontSize: 11.5, color: Colors.white60)),
            ]),
          ),
        ],
      );
    });
  }

  Widget _board(Map<String, dynamic> p, double size) {
    final out = p['out'] == true;
    final game = p['game'] as Map;
    final grid =
        (game['grid'] as List).map((r) => (r as List).cast<int?>()).toList();
    return SizedBox(
      width: size,
      child: Column(children: [
        Text(p['name'] ?? 'RAKİP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: out ? Colors.white38 : const Color(0xFFFFD36A))),
        Text('${game['score'] ?? 0}',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.1,
                color: Colors.white)),
        SizedBox(
          height: 16,
          child: FittedBox(
            child: BattleHearts(
                lives: p['lives'] ?? 5, critical: p['lives'] == 1 && !out),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF101F3B),
            border: Border.all(
                color: out ? const Color(0xFF26324A) : const Color(0xFF3A5C92),
                width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0xFF070F1E), offset: Offset(0, 4)),
            ],
          ),
          child: Stack(fit: StackFit.expand, children: [
            RepaintBoundary(
                child: CustomPaint(
                    key: ValueKey('battle-watch-board-${p['id']}'),
                    painter: BattlePreviewPainter(grid, palette))),
            if (out)
              ColoredBox(
                color: const Color(0xC0070F1E),
                child: Center(
                  child: Text('ELENDİ',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF8B85))),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class BattlePreviewPainter extends CustomPainter {
  final List<List<int?>> board;
  final List<Color> palette;
  BattlePreviewPainter(this.board, this.palette);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    final n = board.length;
    final cell = min(size.width, size.height) / n;
    if (cell >= 14) {
      // İzleme ekranındaki büyük tahta: oyun tahtasıyla aynı piksel bloklar.
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          final color = board[r][c];
          final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
          if (color == null || color == BlockBlastEngine.saltCell) {
            paintEmptyCell(canvas, rect.deflate(.5));
          } else {
            paintBlockCell(canvas, rect.deflate(1), palette[color]);
          }
        }
      }
      paintSalt(canvas, board, cell);
      return;
    }
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        var color = board[r][c];
        if (color == BlockBlastEngine.saltCell) color = null;
        paint.color = color == null ? const Color(0xFF1C3153) : palette[color];
        final rect = Rect.fromLTWH(c * cell, r * cell, cell - 1, cell - 1);
        canvas.drawRect(rect, paint);
        if (color != null && cell >= 6) {
          // Piksel blok: üst kenarda açık şerit.
          paint.color = Color.lerp(palette[color], Colors.white, .35)!;
          canvas.drawRect(
              Rect.fromLTWH(rect.left, rect.top, rect.width, 1), paint);
        }
      }
    }
    paintSalt(canvas, board, cell, inset: 0);
  }

  @override
  bool shouldRepaint(BattlePreviewPainter old) {
    if (old.board.length != board.length) return true;
    for (var r = 0; r < board.length; r++) {
      for (var c = 0; c < board.length; c++) {
        if (board[r][c] != old.board[r][c]) return true;
      }
    }
    return false;
  }
}

class BattleResult extends StatefulWidget {
  final BlockBattleSession session;
  final VoidCallback onClose;
  const BattleResult({super.key, required this.session, required this.onClose});

  @override
  State<BattleResult> createState() => _BattleResultState();
}

class _BattleResultState extends State<BattleResult>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final state = session.state ?? {};
    final winnerId = state['winner'];
    final isWinner = winnerId != null && winnerId == session.me;
    final winnerPlayer =
        session.players.where((p) => p['id'] == winnerId).firstOrNull;

    final duration = state['startAt'] is int
        ? max(
            0,
            ((state['endedAt'] as int? ?? session.now) -
                    (state['startAt'] as int)) ~/
                1000)
        : 0;

    final mine = session.mine ??
        (session.players.isNotEmpty ? session.players.first : null);
    final opponent = session.opponent ??
        (session.players.length > 1 ? session.players[1] : null);

    final reduced = MediaQuery.disableAnimationsOf(context);

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xF20A1325),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final scale =
                      reduced ? 1.0 : (0.85 + 0.15 * _scaleAnimation.value);
                  final opacity =
                      reduced ? 1.0 : _fadeAnimation.value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101C35),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isWinner
                          ? const Color(0x55FFD700)
                          : Colors.white.withValues(alpha: 0.12),
                      width: isWinner ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isWinner ? const Color(0x33FFD700) : Colors.black54,
                        blurRadius: 28,
                        spreadRadius: isWinner ? 1 : 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Hero: Icon + Title + Subtitle
                      _buildHero(
                          isWinner, winnerId == null, winnerPlayer, reduced,
                          place:
                              session.trio ? (mine?['place'] as int?) : null),

                      // 2. Game-over reason badge
                      _buildReasonBadge(state['reason'] as String?, isWinner),

                      // 3. Player comparison (VS) / üçlüde sıralama
                      if (session.trio)
                        _buildStandings(winnerId)
                      else if (session.players.isNotEmpty)
                        _buildVsComparison(mine, opponent, winnerId),

                      // 4. Match summary
                      _buildMatchSummary(
                        duration,
                        mine?['damage'] as int? ?? 0,
                        mine?['boardOuts'] as int? ?? 0,
                      ),

                      const SizedBox(height: 16),

                      // 5. Actions: Rematch & Leave
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool isWinner, bool isDraw,
      Map<String, dynamic>? winnerPlayer, bool reduced,
      {int? place}) {
    final title = isDraw
        ? 'MAÇ BİTTİ'
        : isWinner
            ? 'ZAFER'
            : place != null
                ? '$place. SIRA'
                : 'MAĞLUBİYET';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isWinner && !reduced)
              SizedBox(
                width: 120,
                height: 80,
                child: CustomPaint(
                  painter: _VictoryConfettiPainter(_animController.value),
                ),
              ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isWinner
                      ? [const Color(0x55FFD700), const Color(0x15FFD700)]
                      : [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05)
                        ],
                ),
                border: Border.all(
                  color: isWinner ? const Color(0xAAFFD700) : Colors.white24,
                  width: 1.5,
                ),
                boxShadow: isWinner
                    ? [
                        const BoxShadow(
                          color: Color(0x44FFD700),
                          blurRadius: 18,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                isWinner ? Icons.emoji_events_rounded : Icons.flag_rounded,
                size: 36,
                color: isWinner
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFB0BEC5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isWinner ? 30 : 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: isWinner ? const Color(0xFFFFE082) : const Color(0xFFECEFF1),
          ),
        ),
        if (winnerPlayer != null) ...[
          const SizedBox(height: 2),
          Text(
            'Kazanan: ${winnerPlayer['name']}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReasonBadge(String? reason, bool isWinner) {
    final trio = widget.session.trio;
    final label = trio
        ? (isWinner ? 'SON AYAKTA KALAN SENSİN' : 'ELENDİN')
        : switch (reason) {
            'score' => isWinner ? 'RAKİBİN CANI BİTTİ' : 'CANLARIN TÜKENDİ',
            'board_out' =>
              isWinner ? 'RAKİPTE HAMLE KALMADI' : 'HAMLE KALMADI · BOARD-OUT',
            'resigned' => isWinner ? 'RAKİP MAÇTAN AYRILDI' : 'MAÇTAN AYRILDIN',
            'disconnect' =>
              isWinner ? 'RAKİBİN BAĞLANTISI KOPTU' : 'BAĞLANTI ZAMAN AŞIMI',
            'expired' => 'ODA SÜRESİ DOLDU',
            _ => 'MAÇ TAMAMLANDI',
          };
    final icon = switch (reason) {
      'score' => Icons.favorite_border_rounded,
      'board_out' => Icons.grid_off_rounded,
      'resigned' => Icons.logout_rounded,
      'disconnect' => Icons.wifi_off_rounded,
      'expired' => Icons.hourglass_bottom_rounded,
      _ => Icons.sports_esports_rounded,
    };
    final accentColor =
        isWinner ? const Color(0xFFFFD36A) : const Color(0xFF8CCBFF);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accentColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVsComparison(Map<String, dynamic>? mine,
      Map<String, dynamic>? opponent, dynamic winnerId) {
    if (mine != null && opponent != null) {
      final myWon = mine['id'] == winnerId;
      final oppWon = opponent['id'] == winnerId;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _playerCard(mine, isMe: true, isWinner: myWon)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'VS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          Expanded(child: _playerCard(opponent, isMe: false, isWinner: oppWon)),
        ],
      );
    }

    return Column(
      children: [
        for (final p in widget.session.players)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _playerCard(p,
                isMe: p['id'] == widget.session.me,
                isWinner: p['id'] == winnerId),
          ),
      ],
    );
  }

  /// Üçlü maç sonucu: oyuncular bitiş sırasına göre.
  Widget _buildStandings(dynamic winnerId) {
    final ranked = [...widget.session.players]..sort((a, b) =>
        ((a['place'] as int?) ?? 9).compareTo((b['place'] as int?) ?? 9));
    return Column(children: [
      for (final p in ranked)
        Container(
          key: ValueKey('battle-standing-${p['id']}'),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p['id'] == winnerId
                ? const Color(0xFF1E2D4A)
                : const Color(0xFF131F37),
            border: Border.all(
                color: p['id'] == winnerId
                    ? const Color(0xFFFFD36A)
                    : Colors.white.withValues(alpha: 0.08),
                width: 2),
          ),
          child: Row(children: [
            SizedBox(
              width: 28,
              child: Text('${p['place'] ?? '–'}.',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: p['id'] == winnerId
                          ? const Color(0xFFFFD36A)
                          : Colors.white54)),
            ),
            Expanded(
              child: Text(
                  p['id'] == widget.session.me
                      ? '${p['name']} (sen)'
                      : '${p['name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            Text('${p['game']?['score'] ?? 0}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ]),
        ),
    ]);
  }

  Widget _playerCard(Map<String, dynamic> p,
      {required bool isMe, required bool isWinner}) {
    final score = (p['game']?['score'] as int?) ?? 0;
    final name = (p['name'] as String?) ?? (isMe ? 'Sen' : 'Rakip');
    final lives = p['lives'] ?? 0;
    final boardOuts = p['boardOuts'] ?? 0;
    final damage = p['damage'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isWinner ? const Color(0xFF1E2D4A) : const Color(0xFF131F37),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner
              ? const Color(0xFFFFD36A).withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.08),
          width: isWinner ? 1.5 : 1.0,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD36A).withValues(alpha: 0.16),
                  blurRadius: 14,
                  spreadRadius: 0,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isWinner
                  ? const Color(0xFFFFD36A).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isWinner) ...[
                  const Icon(Icons.workspace_premium_rounded,
                      size: 11, color: Color(0xFFFFD36A)),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    isWinner ? 'KAZANAN' : (isMe ? 'SEN' : 'RAKİP'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color:
                          isWinner ? const Color(0xFFFFD36A) : Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
              color: isWinner ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.05,
              color: isWinner ? const Color(0xFFFFD76A) : Colors.white,
            ),
          ),
          Text(
            'PUAN',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isWinner
                  ? const Color(0xFFFFD36A).withValues(alpha: 0.7)
                  : Colors.white38,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: Colors.white10),
          ),
          Text(
            '$lives can · $boardOuts kez hamlesiz',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Rakibe verilen skor hasarı: $damage',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
              color: isWinner ? const Color(0xFFFFE082) : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSummary(int duration, int myDamage, int myBoardOuts) {
    final minutes = duration ~/ 60;
    final seconds = (duration % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
              child: _summaryPill(
                  '⏱', '$minutes:$seconds', 'Maç süresi')),
          _summaryDivider(),
          Expanded(
              child: _summaryPill(
                  '⚔️', '$myDamage hasar', 'Skor Hasarın')),
          _summaryDivider(),
          Expanded(
              child: _summaryPill(
                  '💥', '$myBoardOuts kez', 'Board-out')),
        ],
      ),
    );
  }

  Widget _summaryPill(String emoji, String val, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                val,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 18,
      color: Colors.white12,
    );
  }

  Widget _buildActions() {
    final session = widget.session;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (session.opponentRematchRequested && !session.rematchRequested) ...[
          Container(
            key: const ValueKey('battle-opponent-rematch-notice'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x28FFD76A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x66FFD76A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded,
                    size: 14, color: Color(0xFFFFD36A)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    session.trio
                        ? '${session.opponents.where((p) => p['rematch'] == true).length}/2 oyuncu tekrar oynamak istiyor'
                        : 'Rakip tekrar oynamak istiyor!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFD36A),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (session.rematchRequested) ...[
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              key: const ValueKey('battle-rematch-waiting-button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: null,
              icon: const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white70),
              ),
              label: Text(
                session.trio ? 'Diğerleri bekleniyor…' : 'Rakip bekleniyor…',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5C95), Color(0xFFB06CFF)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44FF5C95),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                key: const ValueKey('battle-rematch-button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => session.requestRematch(),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(
                  session.opponentRematchRequested
                      ? 'Kabul Et ve Tekrar Oyna'
                      : 'Tekrar Oyna',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
        if (session.error != null) ...[
          Container(
            key: const ValueKey('battle-result-error'),
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0x28FF8B85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x55FF8B85)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 14, color: Color(0xFFFF8B85)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    session.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFF8B85),
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 6),
        TextButton(
          onPressed: widget.onClose,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white60,
          ),
          child: const Text(
            'Lobiye dön',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _VictoryConfettiPainter extends CustomPainter {
  final double progress;
  _VictoryConfettiPainter(this.progress);

  static const _palette = [
    Color(0xFFFFD700),
    Color(0xFFFF80AB),
    Color(0xFF5C9BFF),
    Color(0xFF35D0C0),
    Color(0xFFFFFFFF),
    Color(0xFFFFB14E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;
    final center = Offset(size.width / 2, size.height / 2);
    const count = 22;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (var i = 0; i < count; i++) {
      final angle = i * (2 * pi / count) + 0.25;
      final speed = 20.0 + (i % 4) * 10.0;
      final dist = speed * Curves.easeOutCubic.transform(progress);
      final dx = cos(angle) * dist;
      final dy = sin(angle) * dist + (progress * progress * 12);
      final color = _palette[i % _palette.length].withValues(alpha: alpha);

      final paint = Paint()..color = color;
      if (i % 3 == 0) {
        canvas.drawCircle(center + Offset(dx, dy), 2.2, paint);
      } else {
        canvas.save();
        canvas.translate(center.dx + dx, center.dy + dy);
        canvas.rotate(angle + progress * 3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-2, -3, 4, 6),
            const Radius.circular(1),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_VictoryConfettiPainter old) => old.progress != progress;
}
