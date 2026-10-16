import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dokunulduğu hissedilen buton sarmalayıcısı.
///
/// Basınca içerik hafifçe küçülür, aşağı iner ve solar; bırakınca küçük
/// bir yaylanmayla geri gelir. Çok hızlı dokunuşlarda bile basılı hâl en az
/// [_minPressed] kadar görünür (yoksa tıklama fark edilmez). Destekleyen
/// cihazlarda hafif titreşim verir.
///
/// [onTap] null ise buton pasiftir: animasyon ve titreşim olmaz.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.behavior,
    this.pressedScale = 0.94,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HitTestBehavior? behavior;
  final double pressedScale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  static const _minPressed = Duration(milliseconds: 110);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _k = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeOutBack.flipped,
  );
  DateTime? _downAt;
  Timer? _release;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _down() {
    if (!_enabled) return;
    _release?.cancel();
    _downAt = DateTime.now();
    _c.forward();
    if (widget.haptic) HapticFeedback.selectionClick();
  }

  void _up() {
    final at = _downAt;
    _downAt = null;
    if (at == null) {
      // Kaydırma içinde onTapDown gelmeden tamamlanan dokunuş.
      _c.forward(from: _c.value);
      _release = Timer(_minPressed, () {
        if (mounted) _c.reverse();
      });
      return;
    }
    final left = _minPressed - DateTime.now().difference(at);
    _release?.cancel();
    if (left > Duration.zero) {
      _release = Timer(left, () {
        if (mounted) _c.reverse();
      });
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _release?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _enabled ? (_) => _down() : null,
      onTapUp: _enabled ? (_) => _up() : null,
      onTapCancel: _enabled ? _up : null,
      onTap: widget.onTap == null
          ? null
          : () {
              if (_downAt != null) _up();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.mediumImpact();
              widget.onLongPress!();
              _up();
            },
      child: AnimatedBuilder(
        animation: _k,
        child: widget.child,
        builder: (context, child) {
          final k = _k.value;
          if (k == 0) return child!;
          final scale = 1 - (1 - widget.pressedScale) * k;
          return Transform.translate(
            offset: Offset(0, 1.5 * k),
            child: Transform.scale(
              scale: scale,
              child:
                  Opacity(opacity: 1 - 0.18 * k.clamp(0.0, 1.0), child: child),
            ),
          );
        },
      ),
    );
  }
}
