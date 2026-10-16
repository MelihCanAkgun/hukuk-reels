import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/widgets/fit_text.dart';
import '../../core/widgets/pixel_logo.dart';
import '../countdown/countdown_text.dart';
import 'home_store.dart';

const _pixelFont = 'PixelifySans';

/// Mantar pano: iki oyuncunun 24 saatlik notları iğneli kağıtlar hâlinde.
/// Oyuncu 1 (mqcan) erkeksi mavi temalı, Oyuncu 2 (ari) pembe kız temalı not.
class CorkBoard extends StatefulWidget {
  const CorkBoard({super.key});

  @override
  State<CorkBoard> createState() => _CorkBoardState();
}

class _CorkBoardState extends State<CorkBoard> {
  final _store = HomeStore.instance;
  bool _busy = false;

  List<Note> get _notes {
    final now = DateTime.now();
    return [
      for (final n in _store.notes)
        if (n.expires.isAfter(now)) n
    ]..sort((a, b) => a.player.compareTo(b.player));
  }

  bool get _hasMine => _notes.any((n) => n.player == _store.me);

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(color: AppTheme.textPrimary)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.surfaceHigh,
    ));

  Future<void> _run(Future<Map<String, dynamic>> call, String done) async {
    setState(() => _busy = true);
    final r = await call;
    if (!mounted) return;
    setState(() => _busy = false);
    _toast((r['error'] as String?) ?? done);
  }

  Future<void> _write() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _NoteDialog(),
    );
    if (text == null || !mounted) return;
    await _run(_store.addNote(text), 'Not panoya iğnelendi 📌');
    HapticFeedback.lightImpact();
  }

  Future<void> _delete(Note n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgElevated,
        title: const Text('Notu kaldır'),
        content: const Text('Not panodan kaldırılsın mı?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Kaldır',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok == true) await _run(_store.deleteNote(n.id), 'Not kaldırıldı.');
  }

  @override
  Widget build(BuildContext context) {
    final notes = _notes;
    final me = _store.me;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const PixelLogo(kLogoPinPink, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Not Panosu',
                  style: TextStyle(
                      fontFamily: _pixelFont,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
            ),
            if (me != null && !_hasMine)
              FilledButton.icon(
                onPressed: _busy ? null : _write,
                icon: const Icon(Icons.push_pin_rounded, size: 18),
                label: const Text('Not bırak'),
                style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact),
              ),
          ],
        ),
        if (_hasMine)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('Yeni not için önce kendi notunu kaldır.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ),
        const SizedBox(height: 10),
        Container(
          height: 236,
          decoration: BoxDecoration(
            color: const Color(0xFF6B3F22),
            border: Border.all(color: const Color(0xFF4A2A14), width: 2),
          ),
          padding: const EdgeInsets.all(7),
          child: CustomPaint(
            painter: _CorkPainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
              child: notes.isEmpty
                  ? const Center(
                      child: Text('Henüz not yok…\nilk notu sen iğnele 💌',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: _pixelFont,
                              fontSize: 16,
                              height: 1.3,
                              color: Color(0xFF5A3418))),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < notes.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(
                            child: notes.length == 1
                                ? FractionallySizedBox(
                                    widthFactor: 0.62,
                                    child: _paper(notes[i], me))
                                : _paper(notes[i], me),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paper(Note n, int? me) => NotePaper(
        note: n,
        onDelete:
            (n.player == me || me == 1) && !_busy ? () => _delete(n) : null,
      );
}

/// Tek bir iğneli not kağıdı. Oyuncu 2 (ari): pembe, fiyonk/lale/kalp;
/// Oyuncu 1 (mqcan): sarı-mavi, joystick/oyun kolu.
class NotePaper extends StatelessWidget {
  const NotePaper({super.key, required this.note, this.onDelete});

  final Note note;
  final VoidCallback? onDelete;

  bool get _girl => note.player == 2;

  @override
  Widget build(BuildContext context) {
    final girl = _girl;
    final ink = girl ? const Color(0xFFB8285A) : const Color(0xFF22355E);
    final left = remainingText(note.expires.difference(DateTime.now()));
    return Transform.rotate(
      angle: girl ? 0.035 : -0.03,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: girl
                    ? const [Color(0xFFFFE7AE), Color(0xFFFFC6D9)]
                    : const [Color(0xFFF9E57F), Color(0xFFF0D158)],
              ),
              border: Border(
                top: BorderSide(
                    color: girl
                        ? const Color(0xFFFF8FB6)
                        : const Color(0xFF4F7FD0),
                    width: 6),
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x55000000),
                    offset: Offset(3, 4),
                    blurRadius: 0),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 4),
                    child: FitText(
                      note.text,
                      maxSize: 26,
                      minSize: 8,
                      style: TextStyle(
                          fontFamily: _pixelFont,
                          height: 1.15,
                          color: ink,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 0, 28, 6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '— ${note.name}'
                      '${left == null ? '' : ' · $left kaldı'}',
                      maxLines: 1,
                      style: TextStyle(
                          fontFamily: _pixelFont,
                          fontSize: 12,
                          color: ink.withValues(alpha: 0.75)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tema süsleri (köşelerde, yazının altında kalmaz).
          if (girl) ...[
            const Positioned(
                left: 4, top: 12, child: PixelLogo(kLogoBow, size: 20)),
            const Positioned(
                left: 4, bottom: 4, child: PixelLogo(kLogoTulip, size: 16)),
            const Positioned(
                right: 4, bottom: 5, child: PixelLogo(kLogoHeart, size: 15)),
          ] else ...[
            const Positioned(
                left: 4, top: 13, child: PixelLogo(kLogoJoystick, size: 17)),
            const Positioned(
                left: 4, bottom: 4, child: PixelLogo(kLogoStar, size: 15)),
            const Positioned(
                right: 4, bottom: 4, child: PixelLogo(kLogoGames, size: 18)),
          ],
          // İğne
          Positioned(
            top: -6,
            left: 0,
            right: 0,
            child: Center(
              child: PixelLogo(girl ? kLogoPinPink : kLogoPinBlue, size: 22),
            ),
          ),
          if (onDelete != null)
            Positioned(
              right: -6,
              top: -2,
              child: Semantics(
                button: true,
                label: 'Notu kaldır',
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B1220),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 15, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mantar dokusu: sabit tohumlu piksel benekler (her çizimde aynı).
class _CorkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFC79A64));
    final dark = Paint()..color = const Color(0xFFA97B47);
    final light = Paint()..color = const Color(0xFFDDB27A);
    var seed = 7;
    int next() => seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    const px = 3.0;
    final count = (size.width * size.height / 70).round();
    for (var i = 0; i < count; i++) {
      final x = (next() % (size.width / px).floor()) * px;
      final y = (next() % (size.height / px).floor()) * px;
      canvas.drawRect(
          Rect.fromLTWH(x, y, px, px), next() % 3 == 0 ? light : dark);
    }
  }

  @override
  bool shouldRepaint(_CorkPainter old) => false;
}

/// Not yazma penceresi (en fazla 200 karakter, 8 satır).
class _NoteDialog extends StatefulWidget {
  const _NoteDialog();

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _c.text.trim();
    final ok = text.isNotEmpty && text.split('\n').length <= 8;
    return AlertDialog(
      backgroundColor: AppTheme.bgElevated,
      title: const Row(children: [
        PixelLogo(kLogoPinPink, size: 22),
        SizedBox(width: 8),
        Text('Panoya not bırak'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _c,
            autofocus: true,
            maxLength: 200,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Ne yazmak istersin?',
              border: OutlineInputBorder(),
            ),
          ),
          const Text('Not 24 saat panoda kalır; diğer oyuncuya bildirim gider.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç')),
        FilledButton(
            onPressed: ok ? () => Navigator.of(context).pop(text) : null,
            child: const Text('İğnele 📌')),
      ],
    );
  }
}
