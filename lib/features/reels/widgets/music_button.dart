import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/services/audio_service.dart';
import 'music_control_panel.dart';

/// Herhangi bir ekranın üst barına konulabilen müzik düğmesi. Dokununca
/// müzik denetim masasını üstte (Overlay) açar; böylece oyun oynarken de
/// müzik değiştirilebilir / durdurulabilir. Parça yoksa hiç görünmez.
class MusicButton extends StatefulWidget {
  final Color color;
  const MusicButton({super.key, this.color = AppTheme.accent});

  @override
  State<MusicButton> createState() => _MusicButtonState();
}

class _MusicButtonState extends State<MusicButton> {
  OverlayEntry? _entry;
  bool get _open => _entry != null;

  void _toggle() => _open ? _close() : _openPanel();

  void _openPanel() {
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(ctx).padding.top + 54,
            right: 12,
            child: MusicControlPanel(onClose: _close),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
    setState(() {});
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AudioService.instance.hasTracks) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _open
              ? widget.color.withValues(alpha: 0.2)
              : AppTheme.surfaceHigh,
          shape: BoxShape.circle,
          border: Border.all(color: _open ? widget.color : AppTheme.border),
        ),
        child: Icon(Icons.music_note_rounded, color: widget.color, size: 19),
      ),
    );
  }
}
