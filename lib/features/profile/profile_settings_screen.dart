import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hukuk_reels/core/widgets/pixel_logo.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/data/questions_data.dart';
import '../../core/models/quiz_question.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/avatar_sync.dart';
import '../../core/services/avatar_bridge.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/sfx_service.dart';
import '../../core/services/social_bridge.dart';
import '../beat/beat_mode_screen.dart';
import '../game/block_leaderboard.dart';
import '../games/games_screen.dart';
import '../reels/screens/reels_screen.dart';
import 'avatar_editor_screen.dart';
import 'profile_avatar.dart';

/// Profil (takma ad, fotoğraf, ilerleme, sorular) + Ayarlar (ses, sıralama,
/// veri) ekranı.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _progress = ProgressService.instance;

  /// Sıralama servisinin son durumu (oyuncu adı, bildirim durumu).
  Map<String, dynamic> _social = const {};
  bool _socialLoaded = false;
  bool _renaming = false;
  bool _avatarBusy = false;
  bool _showAllWrong = false;
  bool _showAllRight = false;

  static const _previewCount = 5;

  @override
  void initState() {
    super.initState();
    _loadSocial();
  }

  Future<void> _loadSocial() async {
    final result = await AvatarSync.instance.sync(await socialCall('state'));
    if (!mounted) return;
    setState(() {
      _social = result;
      _socialLoaded = true;
    });
    final name = _serverName;
    if (name != null) await _progress.setNick(name);
  }

  bool get _connected => _social['connected'] == true;

  /// Oyuncu 1 (yönetici): fotoğraf indirme ile ilgili bilgiler yalnız ona.
  bool get _isAdmin => _connected && _social['me'] == 1;

  Map<String, dynamic>? get _me {
    final players = _social['players'];
    if (players is! List) return null;
    for (final p in players) {
      if (p is Map && p['id'] == _social['me']) {
        return p.cast<String, dynamic>();
      }
    }
    return null;
  }

  Map<String, dynamic>? get _partner {
    final players = _social['players'];
    if (players is! List) return null;
    for (final p in players) {
      if (p is Map && p['id'] != _social['me'] && p['active'] == 1) {
        return p.cast<String, dynamic>();
      }
    }
    return null;
  }

  /// Fotoğraf değişikliğini (bağlıysa) hemen sunucuya iletir.
  Future<void> _syncAvatar() async {
    if (!_connected) return;
    final result = await AvatarSync.instance.sync(_social);
    if (!mounted) return;
    setState(() => _social = result);
    final error = AvatarSync.instance.lastError;
    if (error != null) _toast('Fotoğraf eşitlenemedi: $error');
  }

  String? get _serverName {
    final n = _me?['name'];
    return n is String && n.trim().isNotEmpty ? n.trim() : null;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _progress.stats;
    final byId = {for (final q in kQuestions) q.id: q};

    final answered = <(QuizQuestion, QuestionStat)>[
      for (final e in stats.entries)
        if (byId.containsKey(e.key)) (byId[e.key]!, e.value),
    ];
    final wrongOnes = answered.where((t) => t.$2.wrong > 0).toList()
      ..sort((a, b) => b.$2.wrong.compareTo(a.$2.wrong));
    final rightOnes = answered
        .where((t) => t.$2.wrong == 0 && t.$2.correct > 0)
        .toList()
      ..sort((a, b) => b.$2.correct.compareTo(a.$2.correct));

    final totC = answered.fold(0, (s, t) => s + t.$2.correct);
    final totW = answered.fold(0, (s, t) => s + t.$2.wrong);
    final totA = totC + totW;
    final pct = totA == 0 ? 0 : (totC / totA * 100).round();

    final solved = _progress.solvedIds;
    final solvedInPool = kQuestions.where((q) => solved.contains(q.id)).length;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                      16, 4, 16, 28 + MediaQuery.paddingOf(context).bottom),
                  children: [
                    _profileCard(pct, solvedInPool),
                    _sectionTitle('İLERLEME', Icons.insights_rounded),
                    _successCard(pct, totC, totW, totA),
                    const SizedBox(height: 10),
                    _poolCard(solvedInPool),
                    const SizedBox(height: 10),
                    _recordsCard(),
                    _sectionTitle('SORULAR', Icons.school_rounded),
                    if (wrongOnes.isNotEmpty) ...[
                      _practiceRow(wrongOnes.map((t) => t.$1).toList()),
                      const SizedBox(height: 10),
                    ],
                    _questionGroup(
                      title: 'Yanlış yaptıkların',
                      color: AppTheme.danger,
                      icon: Icons.cancel_rounded,
                      items: wrongOnes,
                      empty: 'Henüz yanlışın yok. Devam! 🎉',
                      showAll: _showAllWrong,
                      onToggle: () =>
                          setState(() => _showAllWrong = !_showAllWrong),
                    ),
                    const SizedBox(height: 10),
                    _questionGroup(
                      title: 'Doğru yaptıkların',
                      color: AppTheme.success,
                      icon: Icons.check_circle_rounded,
                      items: rightOnes,
                      empty: 'Henüz hatasız çözülmüş soru yok.',
                      showAll: _showAllRight,
                      onToggle: () =>
                          setState(() => _showAllRight = !_showAllRight),
                    ),
                    _sectionTitle('SES', Icons.graphic_eq_rounded),
                    _soundGroup(),
                    _sectionTitle(
                        'SIRALAMA VE BİLDİRİMLER', Icons.emoji_events_rounded),
                    _group([_leaderboardRow()]),
                    _sectionTitle('VERİ', Icons.storage_rounded),
                    _group([
                      _actionRow(
                        icon: Icons.restart_alt_rounded,
                        color: AppTheme.accent,
                        title: 'Soru havuzunu sıfırla',
                        subtitle: 'Çözülmüşlük işaretleri temizlenir, '
                            'istatistikler kalır. Yeni test başlar.',
                        onTap: _onResetPool,
                      ),
                    ]),
                    const SizedBox(height: 10),
                    _group([
                      _actionRow(
                        icon: Icons.delete_forever_rounded,
                        color: AppTheme.danger,
                        title: 'Her şeyi sıfırla',
                        subtitle: 'İlerleme, istatistikler, test ve oyun '
                            'rekorları silinir. Profilin korunur.',
                        onTap: _onResetAll,
                      ),
                    ], borderColor: AppTheme.danger.withValues(alpha: 0.35)),
                    const SizedBox(height: 30),
                    const Center(
                      child: Text(
                        'Sendeyiz Arifecim 🫂',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Hukuk Reels',
                        style: TextStyle(
                          fontSize: 11.5,
                          letterSpacing: 0.6,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Üst bar ─────────────────────────

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Geri',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 2),
            const Expanded(
              child: Text(
                'Profil & Ayarlar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );

  // ───────────────────────── Profil kartı ─────────────────────────

  Widget _profileCard(int pct, int solvedInPool) {
    return ValueListenableBuilder<int>(
      valueListenable: _progress.profileChanges,
      builder: (context, _, __) {
        final nick = _serverName ?? _progress.nick;
        final status = !_socialLoaded
            ? 'Bağlanıyor…'
            : _connected
                ? 'İkimizin sıralamasında'
                : 'Sıralamaya henüz katılmadın';
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A1E30), AppTheme.bgElevated],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Profil fotoğrafını değiştir',
                    child: GestureDetector(
                      onTap: _avatarBusy ? null : _onAvatarTap,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const ProfileAvatar(size: 84),
                          if (_avatarBusy)
                            const Positioned.fill(
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: AppTheme.accent),
                            ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: AppTheme.bg, width: 2.5),
                              ),
                              child: const Icon(Icons.photo_camera_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                nick ?? 'Takma ad yok',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: nick == null
                                      ? AppTheme.textMuted
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: _renaming
                                  ? const Padding(
                                      padding: EdgeInsets.all(9),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.accent),
                                    )
                                  : IconButton(
                                      tooltip: 'Takma adı değiştir',
                                      padding: EdgeInsets.zero,
                                      iconSize: 18,
                                      onPressed: _onEditNick,
                                      icon: const Icon(Icons.edit_rounded,
                                          color: AppTheme.textSecondary),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _connected
                                    ? AppTheme.success
                                    : AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _miniStat('%$pct', 'başarı'),
                  _miniDivider(),
                  _miniStat('$solvedInPool', 'çözülen soru'),
                  _miniDivider(),
                  _miniStat(_formatScore(_progress.blockHigh), 'Block Blast'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
            ),
          ],
        ),
      );

  Widget _miniDivider() => Container(
        width: 1,
        height: 28,
        color: AppTheme.border,
      );

  static String _formatScore(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  // ───────────────────────── Fotoğraf / takma ad ─────────────────────────

  void _onAvatarTap() {
    if (!avatarPickerSupported) {
      _toast('Profil fotoğrafı web uygulamasında eklenebilir.');
      return;
    }
    if (_progress.avatar == null) {
      _pickAvatar();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const ProfileAvatar(size: 96),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Fotoğrafını yalnızca oyuncu kodu kayıtlı olan ikiniz '
                  'görebilirsiniz. Konum bilgisi silinir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 8),
              _sheetButton(
                icon: Icons.photo_library_rounded,
                label: 'Yeni fotoğraf seç',
                color: AppTheme.accent,
                onTap: () {
                  // Dosya penceresi dokunuşun içinde açılmalı (Safari).
                  _pickAvatar();
                  Navigator.of(ctx).pop();
                },
              ),
              _sheetButton(
                icon: Icons.delete_outline_rounded,
                label: 'Fotoğrafı kaldır',
                color: AppTheme.danger,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _progress.setAvatarDataUrl(null);
                  _toast('Profil fotoğrafı kaldırıldı.');
                  await _syncAvatar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: color == AppTheme.danger ? color : AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      );

  /// Seç → düzenle (boyut, piksel çıkartmalar) → tam çözünürlükte çiz →
  /// bağlıysa tam kalite + görüntü kopyasını birlikte yükle.
  Future<void> _pickAvatar() async {
    final picked = await pickAvatarSource();
    if (!mounted || picked.isEmpty) return;
    if (picked.startsWith('error:')) {
      _toast(picked.substring(6));
      return;
    }
    final Map<String, dynamic> src;
    final Uint8List preview;
    try {
      src = jsonDecode(picked) as Map<String, dynamic>;
      preview = base64Decode((src['preview'] as String).split(',').last);
    } catch (_) {
      forgetAvatarSource();
      _toast('Bu fotoğraf açılamadı.');
      return;
    }
    final spec = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => AvatarEditorScreen(
          preview: preview,
          srcWidth: src['w'] as int,
          srcHeight: src['h'] as int,
          admin: _isAdmin,
        ),
      ),
    );
    if (spec == null || !mounted) {
      forgetAvatarSource();
      return;
    }
    setState(() => _avatarBusy = true);
    try {
      final rendered = await renderAvatar(jsonEncode(spec));
      if (!mounted) return;
      if (rendered.startsWith('error:')) {
        _toast(rendered.substring(6));
        return;
      }
      final r = jsonDecode(rendered) as Map<String, dynamic>;
      final thumb = r['thumb'] as String;
      final side = r['side'];
      if (_connected) {
        final result = await socialCall('avatarPutFull', {'data': thumb});
        if (!mounted) return;
        final error = result['error'] as String?;
        if (error == null) {
          setState(() => _social = result);
          await _progress.setAvatarFromServer(
              thumb.split(',').last, _me?['avatar'] as String? ?? '');
          HapticFeedback.lightImpact();
          _toast(_isAdmin
              ? 'Profil fotoğrafı tam kalitede yüklendi ($side×$side).'
              : 'Profil fotoğrafı güncellendi.');
          return;
        }
        // Tam kalite yüklenemedi: görüntü kopyası sonra eşitlensin.
        final ok = await _progress.setAvatarDataUrl(thumb);
        if (!mounted) return;
        _toast(!ok
            ? 'Bu fotoğraf kaydedilemedi.'
            : _isAdmin
                ? 'Tam kalite yüklenemedi ($error). Fotoğraf küçük boyutla kaydedildi.'
                : 'Profil fotoğrafı kaydedildi; sunucuya gönderilemedi ($error).');
        if (ok) await _syncAvatar();
        return;
      }
      final ok = await _progress.setAvatarDataUrl(thumb);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _toast(ok
          ? 'Profil fotoğrafı bu cihazda güncellendi. Diğer oyuncunun da '
              'görmesi için sıralamaya oyuncu kodunla katıl.'
          : 'Bu fotoğraf kaydedilemedi.');
    } finally {
      forgetAvatarSource();
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _onEditNick() async {
    if (!_connected) {
      final go = await _confirm(
        icon: Icons.emoji_events_rounded,
        color: AppTheme.accent,
        title: 'Takma ad sıralamadan gelir',
        message: 'Takma adını belirlemek için "İkimizin sıralaması"na '
            'oyuncu kodunla katıl. Katıldıktan sonra buradan değiştirebilirsin.',
        confirmLabel: 'Sıralamaya git',
      );
      if (go && mounted) await _openLeaderboard();
      return;
    }
    final controller =
        TextEditingController(text: _serverName ?? _progress.nick ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _NickDialog(controller: controller),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _serverName) return;
    setState(() => _renaming = true);
    final result = await socialCall('rename', {'name': trimmed});
    if (!mounted) return;
    final error = result['error'] as String?;
    setState(() {
      _renaming = false;
      if (error == null) _social = result;
    });
    if (error != null) {
      _toast(error);
      return;
    }
    await _progress.setNick(_serverName ?? trimmed);
    _toast('Takma adın güncellendi.');
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
  }

  // ───────────────────────── Bölümler ─────────────────────────

  Widget _sectionTitle(String title, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title, // Türkçe büyük harfle verilir (İ/I)
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );

  /// Ayrı satırları tek kart içinde ince çizgilerle gruplar.
  Widget _group(List<Widget> rows, {Color? borderColor}) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(const Divider(
            height: 1, thickness: 1, indent: 64, color: AppTheme.border));
      }
      children.add(rows[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: children),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 20),
      );

  Widget _actionRow({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        child: Row(
          children: [
            _iconBox(icon, color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: color == AppTheme.danger
                          ? AppTheme.danger
                          : AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                (onTap == null
                    ? const SizedBox.shrink()
                    : const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textMuted, size: 20)),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── İlerleme ─────────────────────────

  Widget _successCard(int pct, int totC, int totW, int totA) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: totA == 0 ? 0 : pct / 100,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppTheme.border.withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                ),
                Center(
                  child: Text(
                    '%$pct',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Başarı oranın',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _statRow(Icons.check_circle_rounded, AppTheme.success,
                    '$totC doğru cevap'),
                const SizedBox(height: 6),
                _statRow(Icons.cancel_rounded, AppTheme.danger,
                    '$totW yanlış cevap'),
                const SizedBox(height: 6),
                _statRow(Icons.functions_rounded, AppTheme.textMuted,
                    'toplam $totA cevap'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, Color color, String text) => Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );

  Widget _poolCard(int solvedInPool) {
    final pool = _progress.poolSize;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded,
                  color: AppTheme.accent, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Soru havuzu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$solvedInPool / $pool çözüldü',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pool == 0 ? 0 : solvedInPool / pool,
              minHeight: 6,
              backgroundColor: AppTheme.border.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Çözdüğün sorular sonraki testlerde tekrar karşına çıkmaz.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordsCard() {
    Widget record(List<String> logo, String name, int value) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                PixelLogo(logo, size: 26),
                const SizedBox(height: 6),
                Text(
                  _formatScore(value),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        );
    return Row(
      children: [
        record(kLogoBlockBlast, 'Block Blast', _progress.blockHigh),
        const SizedBox(width: 8),
        record(kLogoFlappyCat, 'Flappy Cat', _progress.flappyHigh),
        const SizedBox(width: 8),
        record(kLogoSubwaySilly, 'Subway Silly', _progress.subwayHigh),
      ],
    );
  }

  // ───────────────────────── Sorular ─────────────────────────

  Widget _practiceRow(List<QuizQuestion> wrong) {
    Widget button({
      required String label,
      IconData? icon,
      Widget? logo,
      required bool primary,
      required VoidCallback onTap,
    }) =>
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: primary ? AppTheme.pinkGradient : null,
                color: primary ? null : AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: primary ? null : Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  logo ??
                      Icon(icon,
                          size: 18,
                          color: primary ? Colors.white : AppTheme.textPrimary),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: primary ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Row(
      children: [
        button(
          label: 'Yanlışlarımı çöz',
          icon: Icons.replay_rounded,
          primary: true,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ReelsScreen(retryQuestions: wrong))),
        ),
        const SizedBox(width: 10),
        button(
          label: 'Yanlışları döv',
          logo: const PixelBatIcon(size: 20),
          primary: false,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BeatModeScreen(questions: wrong))),
        ),
      ],
    );
  }

  Widget _questionGroup({
    required String title,
    required Color color,
    required IconData icon,
    required List<(QuizQuestion, QuestionStat)> items,
    required String empty,
    required bool showAll,
    required VoidCallback onToggle,
  }) {
    final visible = showAll ? items : items.take(_previewCount).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                empty,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
            )
          else ...[
            for (final t in visible) _questionTile(t.$1, t.$2),
            if (items.length > _previewCount)
              InkWell(
                onTap: onToggle,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        showAll
                            ? 'Daha az göster'
                            : 'Tümünü göster (${items.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent,
                        ),
                      ),
                      Icon(
                        showAll
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _questionTile(QuizQuestion q, QuestionStat st) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: q.category.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              q.question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (st.wrong > 0) _countChip('✗${st.wrong}', AppTheme.danger),
          if (st.wrong > 0 && st.correct > 0) const SizedBox(width: 5),
          if (st.correct > 0) _countChip('✓${st.correct}', AppTheme.success),
        ],
      ),
    );
  }

  Widget _countChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      );

  // ───────────────────────── Ses ─────────────────────────

  Widget _soundGroup() {
    final audio = AudioService.instance;
    final sfx = SfxService.instance;
    return _group([
      StreamBuilder<bool>(
        stream: audio.playingStream,
        initialData: audio.isPlaying,
        builder: (context, snap) {
          final playing = snap.data ?? false;
          return _actionRow(
            icon: Icons.music_note_rounded,
            color: AppTheme.accent,
            title: 'Arka plan müziği',
            subtitle: playing
                ? (audio.currentTrackName.isEmpty
                    ? 'Çalıyor'
                    : 'Çalıyor · ${audio.currentTrackName}')
                : 'Durduruldu',
            trailing: Switch.adaptive(
              value: playing,
              activeTrackColor: AppTheme.accent,
              onChanged: audio.hasTracks ? (_) => audio.playPause() : null,
            ),
          );
        },
      ),
      StreamBuilder<double>(
        stream: audio.volumeStream,
        initialData: audio.volume,
        builder: (context, snap) => _sliderRow(
          icon: Icons.volume_up_rounded,
          title: 'Müzik sesi',
          value: snap.data ?? audio.volume,
          onChanged: audio.setVolume,
        ),
      ),
      ValueListenableBuilder<double>(
        valueListenable: sfx.volumeListenable,
        builder: (context, v, _) => _sliderRow(
          icon: Icons.graphic_eq_rounded,
          title: 'Oyun efektleri',
          value: v,
          onChanged: sfx.setVolume,
        ),
      ),
    ]);
  }

  Widget _sliderRow({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final v = value.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          _iconBox(icon, AppTheme.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      v < 0.005 ? 'Kapalı' : '%${(v * 100).round()}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: AppTheme.accent,
                    inactiveTrackColor: AppTheme.border,
                    thumbColor: Colors.white,
                    overlayColor: AppTheme.accent.withValues(alpha: 0.15),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: v,
                    onChanged: onChanged,
                    semanticFormatterCallback: (x) => '%${(x * 100).round()}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Sıralama ─────────────────────────

  Widget _leaderboardRow() {
    String subtitle;
    if (!_socialLoaded) {
      subtitle = 'Durum kontrol ediliyor…';
    } else if (_social['native'] == true) {
      subtitle = 'Web uygulamasında kullanılabilir.';
    } else if (!_connected) {
      subtitle = 'Oyuncu kodunla katıl, rekorlarınızı karşılaştırın.';
    } else {
      final bell = _social['subscribed'] == true
          ? 'Bildirimler açık'
          : 'Bildirimler kapalı';
      final me = _me;
      final best = me?['best'];
      subtitle =
          best is num ? 'Rekorun ${_formatScore(best.toInt())} · $bell' : bell;
    }
    final partner = _connected ? _partner : null;
    return _actionRow(
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFFC857),
      title: 'İkimizin sıralaması',
      subtitle: subtitle,
      onTap: _openLeaderboard,
      trailing: partner == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PeerAvatar(
                  id: partner['id'] as int,
                  name: partner['name'] as String?,
                  size: 30,
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted, size: 20),
              ],
            ),
    );
  }

  Future<void> _openLeaderboard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BlockLeaderboard()),
    );
    if (mounted) await _loadSocial();
  }

  // ───────────────────────── Veri ─────────────────────────

  Future<void> _onResetPool() async {
    final ok = await _confirm(
      icon: Icons.restart_alt_rounded,
      color: AppTheme.accent,
      title: 'Soru havuzu sıfırlansın mı?',
      message:
          'Tüm sorular yeniden "çözülmemiş" sayılır ve yeni bir test başlar. '
          'İstatistiklerin (doğru/yanlış geçmişin) silinmez.',
      confirmLabel: 'Sıfırla',
    );
    if (!ok || !mounted) return;
    await _progress.resetPool();
    await _progress.clearSession();
    if (!mounted) return;
    Navigator.of(context).pop('poolReset');
  }

  Future<void> _onResetAll() async {
    final ok = await _confirm(
      icon: Icons.delete_forever_rounded,
      color: AppTheme.danger,
      title: 'Her şey sıfırlansın mı?',
      message: 'Tüm ilerleme, istatistikler, mevcut test ve oyun rekorları '
          'bu cihazdan kalıcı olarak silinir. Profil fotoğrafın ve takma '
          'adın korunur. Bu işlem geri alınamaz.',
      confirmLabel: 'Evet, sıfırla',
    );
    if (!ok || !mounted) return;
    await _progress.resetAll();
    await AudioService.instance.pauseForLifecycle();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GamesScreen()),
      (route) => false,
    );
  }

  Future<bool> _confirm({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.bgElevated,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 42),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _dialogButton(
                      label: 'Vazgeç',
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dialogButton(
                      label: confirmLabel,
                      color: color,
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return res ?? false;
  }
}

Widget _dialogButton({
  required String label,
  required VoidCallback onTap,
  Color? color,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: color == null ? Border.all(color: AppTheme.border) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == null ? AppTheme.textSecondary : Colors.white,
          fontSize: 15,
          fontWeight: color == null ? FontWeight.w700 : FontWeight.w800,
        ),
      ),
    ),
  );
}

/// Takma ad düzenleme penceresi (1–24 karakter, sunucuyla aynı kural).
class _NickDialog extends StatefulWidget {
  const _NickDialog({required this.controller});
  final TextEditingController controller;

  @override
  State<_NickDialog> createState() => _NickDialogState();
}

class _NickDialogState extends State<_NickDialog> {
  bool get _valid {
    final t = widget.controller.text.trim();
    return t.isNotEmpty && t.length <= 24;
  }

  void _submit() {
    if (_valid) Navigator.of(context).pop(widget.controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgElevated,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Takma adını değiştir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'İkimizin sıralamasında da bu ad görünür.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.controller,
              autofocus: true,
              maxLength: 24,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
              cursorColor: AppTheme.accent,
              decoration: InputDecoration(
                hintText: 'Takma ad',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                counterStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.accent),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _dialogButton(
                    label: 'Vazgeç',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Opacity(
                    opacity: _valid ? 1 : 0.45,
                    child: _dialogButton(
                      label: 'Kaydet',
                      color: AppTheme.accent,
                      onTap: _submit,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
