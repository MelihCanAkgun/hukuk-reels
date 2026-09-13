import 'package:flutter/material.dart';

/// Shared arcade-style combo HUD widget used by both singleplayer and
/// multiplayer/battle modes.
///
/// When [combo] is 0 the widget collapses to zero height (no wasted space).
/// As combo rises the visual intensity increases:
///   • 1–2: subtle blue glow
///   • 3–4: purple accent with gentle scale pop
///   • 5+:  gold/legendary glow with stronger pulse
///
/// The three grace "pips" show how many non-clearing moves remain before
/// the combo resets, replacing the old textual "RESET: n" label.
class ComboHud extends StatelessWidget {
  /// Current combo count (0 = hidden).
  final int combo;

  /// Successive non-clearing moves since last clear (0..comboGrace-1).
  final int misses;

  /// Bonus points awarded on the most recent combo clear.
  final int comboBonus;

  /// Maximum allowed misses before combo resets (typically 3).
  final int comboGrace;

  const ComboHud({
    super.key,
    required this.combo,
    required this.misses,
    required this.comboBonus,
    this.comboGrace = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (combo <= 0) return const SizedBox.shrink();

    final reduced = MediaQuery.disableAnimationsOf(context);
    final tier = _ComboTier.fromCombo(combo);
    final remainingGrace = (comboGrace - misses).clamp(0, comboGrace);

    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: _ComboChip(
        key: ValueKey('combo-$combo-$misses'),
        combo: combo,
        comboBonus: comboBonus,
        tier: tier,
        remainingGrace: remainingGrace,
        comboGrace: comboGrace,
        reduced: reduced,
      ),
    );
  }
}

/// Internal animated chip that shows the combo counter, bonus and grace pips.
class _ComboChip extends StatefulWidget {
  final int combo;
  final int comboBonus;
  final _ComboTier tier;
  final int remainingGrace;
  final int comboGrace;
  final bool reduced;

  const _ComboChip({
    super.key,
    required this.combo,
    required this.comboBonus,
    required this.tier,
    required this.remainingGrace,
    required this.comboGrace,
    required this.reduced,
  });

  @override
  State<_ComboChip> createState() => _ComboChipState();
}

class _ComboChipState extends State<_ComboChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.tier.pulseDurationMs),
    );
    if (!widget.reduced && widget.combo > 1) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.tier;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final pulseT = _pulse.value;
        // Subtle scale pop: 1.0 → 1.03..1.06 depending on tier intensity
        final scale = 1.0 + tier.scaleAmount * pulseT;
        // Glow opacity oscillation
        final glowOpacity = (tier.glowBase + tier.glowRange * pulseT)
            .clamp(0.0, 1.0);

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tier.bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: tier.accentColor.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: tier.accentColor.withValues(alpha: 0.25 * glowOpacity),
                  blurRadius: 12 + 6 * pulseT,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ⚡ bolt icon
                Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: tier.accentColor,
                ),
                const SizedBox(width: 2),
                // KOMBO ×N
                Text(
                  '×${widget.combo}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: tier.accentColor,
                    letterSpacing: 0.3,
                    height: 1.0,
                  ),
                ),
                // Bonus points badge (only when > 0)
                if (widget.comboBonus > 0) ...[
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: tier.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${widget.comboBonus}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: tier.accentColor.withValues(alpha: 0.9),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
                // Grace pips separator
                const SizedBox(width: 6),
                // Grace pips (● filled, ○ empty)
                _GracePips(
                  total: widget.comboGrace,
                  remaining: widget.remainingGrace,
                  activeColor: tier.accentColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Three small dots showing remaining grace moves before combo resets.
class _GracePips extends StatelessWidget {
  final int total;
  final int remaining;
  final Color activeColor;
  const _GracePips({
    required this.total,
    required this.remaining,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 2.5),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < remaining
                  ? activeColor.withValues(alpha: 0.85)
                  : activeColor.withValues(alpha: 0.2),
            ),
          ),
        ],
      ],
    );
  }
}

/// Visual tier configuration based on combo magnitude.
class _ComboTier {
  final Color accentColor;
  final Color bgColor;
  final double scaleAmount; // max scale delta (e.g. 0.03 = 3%)
  final double glowBase;
  final double glowRange;
  final int pulseDurationMs;

  const _ComboTier({
    required this.accentColor,
    required this.bgColor,
    required this.scaleAmount,
    required this.glowBase,
    required this.glowRange,
    required this.pulseDurationMs,
  });

  /// Low combo (1–2): cool blue, subtle
  static const _low = _ComboTier(
    accentColor: Color(0xFF8CCBFF),
    bgColor: Color(0xFF0D1F38),
    scaleAmount: 0.015,
    glowBase: 0.4,
    glowRange: 0.3,
    pulseDurationMs: 1200,
  );

  /// Mid combo (3–4): purple, moderate pop
  static const _mid = _ComboTier(
    accentColor: Color(0xFFCFA0FF),
    bgColor: Color(0xFF15102E),
    scaleAmount: 0.03,
    glowBase: 0.5,
    glowRange: 0.35,
    pulseDurationMs: 900,
  );

  /// High combo (5+): gold, strong pulse
  static const _high = _ComboTier(
    accentColor: Color(0xFFFFD568),
    bgColor: Color(0xFF1E1608),
    scaleAmount: 0.05,
    glowBase: 0.6,
    glowRange: 0.4,
    pulseDurationMs: 700,
  );

  factory _ComboTier.fromCombo(int combo) {
    if (combo >= 5) return _high;
    if (combo >= 3) return _mid;
    return _low;
  }
}
