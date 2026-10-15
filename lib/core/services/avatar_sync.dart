import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'progress_service.dart';
import 'social_bridge.dart';

/// Profil fotoğraflarını iki oyuncu arasında eşitler.
///
/// Fotoğraflar yalnızca sunucuda (oyuncu koduyla korunan uç noktada) durur;
/// sıralama verisi yalnızca bir sürüm etiketi taşır. Bu sınıf:
///  • bu cihazda seçilen/kaldırılan fotoğrafı sunucuya iletir,
///  • başka cihazda değiştirilen kendi fotoğrafımızı indirir,
///  • diğer oyuncunun fotoğrafını sürüm değiştiğinde indirir.
class AvatarSync {
  AvatarSync._();
  static final AvatarSync instance = AvatarSync._();

  /// Diğer oyuncunun fotoğrafı değişince artar.
  final ValueNotifier<int> changes = ValueNotifier(0);
  final Map<int, (String, Uint8List)> _peers = {};
  Future<Map<String, dynamic>>? _running;

  /// Son başarısız gönderimin kullanıcıya gösterilecek açıklaması.
  String? lastError;

  /// Testlerde sahte sunucu bağlamak için.
  @visibleForTesting
  Future<Map<String, dynamic>> Function(String action,
      [Map<String, dynamic> data]) call = socialCall;

  Uint8List? photoOf(int id) => _peers[id]?.$2;

  /// [state] `socialCall('state')` sonucudur; güncel hâli döndürülür.
  /// Aynı anda tek eşitleme çalışır.
  Future<Map<String, dynamic>> sync(Map<String, dynamic> state) {
    final running = _running;
    if (running != null) return running.then((_) => state);
    return _running = _sync(state).whenComplete(() => _running = null);
  }

  Future<Map<String, dynamic>> _sync(Map<String, dynamic> state) async {
    if (state['connected'] != true || state['players'] is! List) return state;
    final progress = ProgressService.instance;
    final me = state['me'];

    // 1) Bu cihazda bekleyen değişikliği gönder.
    final pending = progress.avatarPending;
    if (pending == 'up' || pending == 'del') {
      final result = pending == 'up'
          ? await call('avatarPut', {'data': progress.avatarDataUrl})
          : await call('avatarDelete');
      final error = result['error'] as String?;
      if (error == null) {
        lastError = null;
        state = result;
        await progress.markAvatarSynced(pending == 'up' ? _versionOf(state, me) : null);
      } else {
        lastError = error;
        final status = result['status'];
        // Geçersiz/çok büyük fotoğrafı her açılışta yeniden göndermeyelim.
        if (status == 400 || status == 413) await progress.markAvatarRejected();
        return state;
      }
    }

    // 2) Sürümleri karşılaştır, değişenleri indir.
    for (final p in (state['players'] as List).whereType<Map>()) {
      final id = p['id'];
      if (id is! int) continue;
      final version = p['avatar'] as String?;
      if (id == me) {
        if (progress.avatarPending != null || version == progress.avatarVersion) {
          continue;
        }
        if (version == null) {
          // Başka cihazda kaldırıldı.
          await progress.setAvatarFromServerRemoved();
        } else {
          final data = await _download(id, version);
          if (data != null) await progress.setAvatarFromServer(data, version);
        }
        continue;
      }
      if (version == null) {
        if (_peers.remove(id) != null) changes.value++;
        continue;
      }
      if (_peers[id]?.$1 == version) continue;
      final data = await _download(id, version);
      if (data == null) continue;
      try {
        _peers[id] = (version, base64Decode(data));
        changes.value++;
      } catch (_) {}
    }
    return state;
  }

  Future<String?> _download(int id, String version) async {
    final r = await call('avatarGet', {'id': id, 'version': version});
    final data = r['data'];
    return r['error'] == null && data is String && r['version'] == version
        ? data
        : null;
  }

  static String? _versionOf(Map<String, dynamic> state, Object? me) {
    for (final p in (state['players'] as List? ?? const []).whereType<Map>()) {
      if (p['id'] == me) return p['avatar'] as String?;
    }
    return null;
  }

  /// Oyuncu sıralamadan ayrılınca başkasının fotoğrafını bellekte tutma.
  void clearPeers() {
    if (_peers.isEmpty) return;
    _peers.clear();
    changes.value++;
  }
}
