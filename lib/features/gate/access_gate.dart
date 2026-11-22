import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/services/gate_bridge.dart';
import '../../core/services/social_bridge.dart';
import '../../core/widgets/pixel_logo.dart';
import '../game/game_leaderboard.dart' show socialApiUrl;

typedef GateCall = Future<Map<String, dynamic>> Function(String action,
    [Map<String, dynamic> data]);

final _tokenFormat = RegExp(r'^[A-Za-z0-9_-]{43}$');

/// Erişim kapısı: uygulama yalnız oyuncu kodu saklı cihazlarda açılır.
///
/// - Yerel derleme: kapı yok.
/// - Saklı, biçimi doğru kod: [child] hemen açılır; arkada /board denetlenir,
///   yalnız kesin 401 kodun yeniden girilmesini ister (kod silinmez).
/// - Kod yok: yalnız giriş ekranı görünür.
class AccessGate extends StatefulWidget {
  const AccessGate({super.key, required this.child});

  final Widget child;

  /// Kapı açık mı? Davet dinleyicisi gibi dış girişler buna bakar.
  static final ValueNotifier<bool> unlocked = ValueNotifier(false);

  // Testler için değiştirilebilir bağımlılıklar.
  @visibleForTesting
  static bool native = gateNative;
  @visibleForTesting
  static String? Function() readStored = storedSocialConfig;
  @visibleForTesting
  static GateCall call = socialCall;

  @visibleForTesting
  static void debugReset() {
    native = gateNative;
    readStored = storedSocialConfig;
    call = socialCall;
    unlocked.value = false;
    _pending = null;
  }

  static VoidCallback? _pending;

  /// [action] kapı açıksa hemen, değilse kapı açıldıktan sonra çalışır
  /// (yalnız son bekleyen eylem tutulur).
  static void whenUnlocked(VoidCallback action) {
    if (unlocked.value) {
      action();
    } else {
      _pending = action;
    }
  }

  static void _open() {
    unlocked.value = true;
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pending());
    }
  }

  /// Saklı oyuncu kodu biçimce geçerli ve geri alınmamış mı? (Ağa gidilmez.)
  /// Sunucu kodu 401 ile reddettiyse social.js `revoked` işaretler; kod
  /// silinmez ama yok sayılır.
  static bool hasStoredCode() {
    try {
      final raw = readStored();
      if (raw == null || raw.isEmpty) return false;
      final config = jsonDecode(raw);
      if (config is! Map || config['revoked'] == true) return false;
      final token = config['token'];
      return token is String && _tokenFormat.hasMatch(token);
    } catch (_) {
      return false;
    }
  }

  @override
  State<AccessGate> createState() => _AccessGateState();
}

class _AccessGateState extends State<AccessGate> {
  late bool _open;
  // Arka plan denetimi kesin 401 verdi: oyuncu ana ekrana dönünce kilitlenir.
  // Açık oyun/ekran asla kapatılmaz.
  bool _lockPending = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    if (AccessGate.native) {
      _open = true;
    } else {
      _open = AccessGate.hasStoredCode();
      if (_open) unawaited(_recheck());
    }
    if (_open) {
      AccessGate._open();
    } else {
      AccessGate.unlocked.value = false;
    }
  }

  // Arka plan denetimi: ağ hatası, zaman aşımı, 5xx, 429 → geçer.
  Future<void> _recheck() async {
    Map<String, dynamic> r;
    try {
      r = await AccessGate.call('recheck', {'url': socialApiUrl});
    } catch (_) {
      return;
    }
    if (!mounted || r['reason'] != 'invalid') return;
    AccessGate.unlocked.value = false; // davetler artık beklemede
    setState(() {
      _lockPending = true;
      _notice = 'Kod doğrulanamadı. Tekrar dene.';
    });
  }

  void _unlock() {
    AccessGate._open();
    setState(() {
      _open = true;
      _lockPending = false;
      _notice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // isCurrentOf, üstteki ekran kapanınca bu widget'ı yeniden kurar.
    final atHome = ModalRoute.isCurrentOf(context) ?? true;
    if (_open && !(_lockPending && atHome)) return widget.child;
    return GateScreen(onUnlocked: _unlock, initialError: _notice);
  }
}

/// Yabancının gördüğü tek ekran: erişim kodu alanı ve "Devam et".
class GateScreen extends StatefulWidget {
  const GateScreen({super.key, required this.onUnlocked, this.initialError});

  final VoidCallback onUnlocked;
  final String? initialError;

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  bool _show = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  static String _message(Object? reason) => switch (reason) {
        'format' => 'Kod biçimi geçersiz.',
        'invalid' => 'Kod doğrulanamadı. Tekrar dene.',
        'rate' => 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.',
        'server' => 'Sunucuya şu an ulaşılamıyor. Biraz sonra tekrar dene.',
        _ => 'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.',
      };

  // Hata sonrası alan yeniden odaklanır (salt-okunurluk kalktıktan sonra).
  void _refocus() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });

  Future<void> _submit() async {
    if (_busy) return; // gönderim başına tek istek
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Kodu girmen gerekiyor.');
      _refocus();
      return;
    }
    if (!_tokenFormat.hasMatch(code)) {
      setState(() => _error = _message('format'));
      _refocus();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    Map<String, dynamic> r;
    try {
      r = await AccessGate.call('verify', {'token': code, 'url': socialApiUrl});
    } catch (_) {
      r = const {'ok': false, 'reason': 'offline'};
    }
    if (!mounted) return;
    if (r['ok'] == true) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _busy = false;
      _error = _message(r['reason']);
    });
    _refocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // Klavye açılınca düğme görünür kalsın (alttan hizalı kaydırma).
              reverse: true,
              padding: const EdgeInsets.all(24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: ExcludeSemantics(
                            child: PixelLogo(kLogoGem, size: 64)),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        header: true,
                        child: const Text('Giriş',
                            textAlign: TextAlign.center,
                            style: AppTheme.screenTitle),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Devam etmek için erişim kodunu gir.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        key: const ValueKey('gate-code'),
                        controller: _code,
                        focusNode: _focus,
                        autofocus: true,
                        obscureText: !_show,
                        autocorrect: false,
                        enableSuggestions: false,
                        readOnly: _busy,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.go,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Erişim kodu',
                          border: const OutlineInputBorder(),
                          errorText: _error,
                          // null tek satırda keserdi (ellipsis); uzun hata metni sarılsın.
                          errorMaxLines: 10,
                          suffixIcon: IconButton(
                            tooltip: _show ? 'Kodu gizle' : 'Kodu göster',
                            onPressed: () => setState(() => _show = !_show),
                            icon: Icon(_show
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          key: const ValueKey('gate-submit'),
                          style: FilledButton.styleFrom(
                              foregroundColor: AppTheme.bg),
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? Semantics(
                                  label: 'Doğrulanıyor',
                                  child: const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : const Text('Devam et',
                                  style: TextStyle(
                                      fontFamily: AppTheme.pixelFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
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
}
