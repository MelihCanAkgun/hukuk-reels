import 'dart:math';
import 'package:flutter/material.dart';

/// ──────────────────────────────────────────
/// Dönen Müzik Diski Göstergesi
///
/// TikTok/Reels tarzı sol altta dönen disk.
/// Parça adını ve animasyonlu nota ikonları gösterir.
/// ──────────────────────────────────────────
class MusicIndicator extends StatefulWidget {
  final String trackName;
  final bool isPlaying;

  const MusicIndicator({
    super.key,
    required this.trackName,
    this.isPlaying = true,
  });

  @override
  State<MusicIndicator> createState() => _MusicIndicatorState();
}

class _MusicIndicatorState extends State<MusicIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.isPlaying) _rotationController.repeat();
  }

  @override
  void didUpdateWidget(covariant MusicIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dönen disk
        AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * pi,
              child: child,
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF1A237E), Color(0xFF121212)],
                stops: [0.3, 1.0],
              ),
              border: Border.all(
                color: const Color(0xFFFF6D00).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(Icons.music_note, color: Color(0xFFFF6D00), size: 16),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Kayan parça adı
        SizedBox(
          width: 130,
          child: _MarqueeText(
            text: '${widget.trackName}  ~  sillycat vibes',
            isPlaying: widget.isPlaying,
          ),
        ),
      ],
    );
  }
}

/// Yatay kayan metin (marquee efekti)
class _MarqueeText extends StatefulWidget {
  final String text;
  final bool isPlaying;

  const _MarqueeText({required this.text, required this.isPlaying});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _animation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: const Offset(-1.0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SlideTransition(
        position: _animation,
        child: Text(
          widget.text,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
