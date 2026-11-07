import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'film_store.dart';
import 'film_widgets.dart';

/// Arcade panel: koyu zemin, ince çerçeve ve yumuşatılmamış "sert" gölge.
BoxDecoration arcadePanel({
  Color color = AppTheme.surface,
  Color border = AppTheme.border,
  Color shadow = const Color(0xFF0B0408),
  double radius = 6,
}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border, width: 1.5),
      boxShadow: [BoxShadow(color: shadow, offset: const Offset(3, 3))],
    );

/// Yorum / yanıt yazma penceresi. Ekranın ÜSTÜNDE açılır: telefonda klavye
/// alttan çıktığı için yazılan metin hiçbir zaman klavyenin altında kalmaz
/// (iPhone'da web uygulaması klavye boşluğunu her zaman bildirmiyor).
/// Vazgeçilirse null döner.
Future<String?> showTextComposer(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
  String? quote,
  String? quoteBy,
  int maxLength = 140,
  String action = 'Gönder',
  bool allowEmpty = false,
}) =>
    showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Kapat',
      barrierColor: Colors.black.withValues(alpha: .6),
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (_, a, __, child) => SlideTransition(
        position: Tween(begin: const Offset(0, -.15), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: a, child: child),
      ),
      // showGeneralDialog temaları taşımaz: açan ekranın (arcade) teması.
      pageBuilder: (c, _, __) => Theme(
        data: Theme.of(context),
        child: _Composer(
          title: title,
          initial: initial,
          hint: hint,
          quote: quote,
          quoteBy: quoteBy,
          maxLength: maxLength,
          action: action,
          allowEmpty: allowEmpty,
        ),
      ),
    );

class _Composer extends StatefulWidget {
  const _Composer({
    required this.title,
    required this.initial,
    required this.hint,
    required this.quote,
    required this.quoteBy,
    required this.maxLength,
    required this.action,
    required this.allowEmpty,
  });

  final String title, initial, hint, action;
  final String? quote, quoteBy;
  final int maxLength;
  final bool allowEmpty;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String get _value => _text.text.replaceAll('\n', ' ').trim();

  @override
  Widget build(BuildContext context) {
    final canSend = widget.allowEmpty || _value.isNotEmpty;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: arcadePanel(
                  color: AppTheme.bgElevated,
                  border: AppTheme.accent,
                  shadow: const Color(0xFF8C1D4A),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const PixelHeart(size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.title,
                              style:
                                  AppTheme.sheetTitle.copyWith(fontSize: 18)),
                        ),
                      ],
                    ),
                    if (widget.quote != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                        decoration: const BoxDecoration(
                          border: Border(
                              left:
                                  BorderSide(color: AppTheme.accent, width: 3)),
                          color: AppTheme.surface,
                        ),
                        child: Text(
                          widget.quoteBy == null
                              ? widget.quote!
                              : '${widget.quoteBy}: ${widget.quote}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.3),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      key: const ValueKey('composer-field'),
                      controller: _text,
                      autofocus: true,
                      maxLength: widget.maxLength,
                      minLines: 2,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          height: 1.3),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.surface,
                        counterStyle: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                const BorderSide(color: AppTheme.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                                color: AppTheme.accent, width: 1.5)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Vazgeç',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                        const SizedBox(width: 6),
                        ArcadeButton(
                          key: const ValueKey('composer-send'),
                          label: widget.action,
                          onTap: canSend
                              ? () => Navigator.pop(context, _value)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pembe, sert gölgeli piksel düğme (basınca gölgeye doğru iner).
class ArcadeButton extends StatefulWidget {
  const ArcadeButton({
    super.key,
    required this.label,
    required this.onTap,
    this.big = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool big, busy;

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.busy;
    final shift = _down ? 3.0 : 0.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onTap!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(shift, shift, 0),
          padding: EdgeInsets.symmetric(
              horizontal: widget.big ? 22 : 16, vertical: widget.big ? 14 : 9),
          decoration: BoxDecoration(
            gradient: enabled ? AppTheme.pinkGradient : null,
            color: enabled ? null : AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: enabled ? const Color(0xFFFFC2D8) : AppTheme.border,
                width: 1.5),
            boxShadow: [
              if (!_down)
                BoxShadow(
                    color: enabled
                        ? const Color(0xFF8C1D4A)
                        : const Color(0xFF0B0408),
                    offset: const Offset(3, 3)),
            ],
          ),
          child: widget.busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white))
              : Text(widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: AppTheme.pixelFont,
                      color: enabled ? Colors.white : AppTheme.textMuted,
                      fontSize: widget.big ? 19 : 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4)),
        ),
      ),
    );
  }
}

/// Beğeni düğmesi: piksel kalp ve sayı. Kendi yorumunda yalnız sayıyı
/// gösterir (kendi yorumunu beğenemezsin).
class LikeButton extends StatelessWidget {
  const LikeButton({
    super.key,
    required this.count,
    required this.liked,
    required this.onTap,
  });

  final int count;
  final bool liked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = count == 0 ? 'Beğen' : '$count';
    return Semantics(
      button: onTap != null,
      label: liked ? 'Beğeniyi geri al' : 'Beğen',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: PixelHeart(
                    key: ValueKey(liked), size: 14, fill: liked ? 2 : 0),
              ),
              if (onTap != null || count > 0) ...[
                const SizedBox(width: 5),
                Text(onTap == null ? '$count' : label,
                    style: TextStyle(
                        color: liked ? AppTheme.accent : AppTheme.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bir oyuncunun incelemesi (Letterboxd'daki gibi): kim, kaç kalp, yorum,
/// beğeni / yanıt satırı ve altında yanıtlar.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.film,
    required this.rating,
    this.trailing,
    this.onError,
  });

  final Film film;
  final FilmRating rating;
  final Widget? trailing;
  final ValueChanged<String>? onError;

  FilmStore get _store => FilmStore.instance;

  Future<void> _reply(BuildContext context) async {
    final text = await showTextComposer(
      context,
      title: 'Yanıtla',
      hint: '${_store.nameOf(rating.player)} ne demiş, ne diyorsun?',
      quote: rating.comment.isEmpty ? null : rating.comment,
      quoteBy: _store.nameOf(rating.player),
      maxLength: 280,
    );
    if (text == null || text.isEmpty) return;
    final error = await _store.reply(film.id, rating.player, text);
    if (error != null) onError?.call(error);
  }

  Future<void> _like(String target, bool like) async {
    final error = await _store.like(film.id, target, like);
    if (error != null) onError?.call(error);
  }

  Future<void> _deleteReply(BuildContext context, FilmReply r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Yanıt silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Vazgeç')),
          TextButton(
              key: const ValueKey('reply-delete-confirm'),
              onPressed: () => Navigator.pop(c, true),
              child:
                  const Text('Sil', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok != true) return;
    final error = await _store.deleteReply(r.id);
    if (error != null) onError?.call(error);
  }

  @override
  Widget build(BuildContext context) {
    final me = _store.me;
    final target = 'c${rating.player}';
    final likes = _store.likesOf(film.id, target);
    final mine = rating.player == me;
    final replies = _store.repliesTo(film.id, rating.player);
    return Container(
      key: ValueKey('review-${rating.player}'),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 6),
      decoration: arcadePanel(
          border:
              mine ? AppTheme.accent.withValues(alpha: .55) : AppTheme.border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlayerAvatar(id: rating.player, size: 34, ring: false),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_store.nameOf(rating.player),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        HeartRow(halves: rating.halves, size: 16),
                        const SizedBox(width: 8),
                        Text(heartsText(rating.halves),
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (rating.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(rating.comment,
                key: ValueKey('review-text-${rating.player}'),
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 15, height: 1.35)),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              if (rating.comment.isNotEmpty)
                LikeButton(
                  key: ValueKey('review-like-${rating.player}'),
                  count: likes.length,
                  liked: me != null && likes.contains(me),
                  onTap: mine || me == null
                      ? null
                      : () => _like(target, !likes.contains(me)),
                ),
              TextButton(
                key: ValueKey('review-reply-${rating.player}'),
                onPressed: () => _reply(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: Text(
                    replies.isEmpty
                        ? '💬 Yanıtla'
                        : '💬 Yanıtla · ${replies.length}',
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          for (final r in replies)
            _ReplyTile(
              reply: r,
              onLike: me == null || r.player == me
                  ? null
                  : (like) => _like('r${r.id}', like),
              onDelete: r.player == me ? () => _deleteReply(context, r) : null,
            ),
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.reply, this.onLike, this.onDelete});

  final FilmReply reply;
  final ValueChanged<bool>? onLike;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final store = FilmStore.instance;
    final likes = store.likesOf(reply.film, 'r${reply.id}');
    final liked = store.me != null && likes.contains(store.me);
    return Container(
      key: ValueKey('reply-${reply.id}'),
      margin: const EdgeInsets.only(left: 14, bottom: 6, right: 4),
      padding: const EdgeInsets.fromLTRB(10, 6, 2, 2),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppTheme.accent, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlayerAvatar(id: reply.player, size: 22, ring: false),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${store.nameOf(reply.player)} · '
                    '${agoText(reply.created, DateTime.now())}',
                    style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(reply.text,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        height: 1.3)),
                Row(
                  children: [
                    LikeButton(
                      key: ValueKey('reply-like-${reply.id}'),
                      count: likes.length,
                      liked: liked,
                      onTap: onLike == null ? null : () => onLike!(!liked),
                    ),
                    if (onDelete != null)
                      InkWell(
                        key: ValueKey('reply-delete-${reply.id}'),
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          child: Text('Sil',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 12)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
