import 'package:flutter/services.dart';

/// Paketlenmiş (`.bin`) görsel varlıklarını çözer.
///
/// Bu dosyalar depoda ham görsel olarak durmaz; uygulama açılışta
/// belleğe çözer.
class PackedAsset {
  PackedAsset._();

  static const List<int> _magic = [0x48, 0x52, 0x4B, 0x31]; // "HRK1"
  static final Uint8List _key = Uint8List.fromList(
    [...'hukuk-reels/k'.codeUnits, 0x9e, 0x13, 0xc4, 0x7f, 0x01, 0xb2, 0x55],
  );
  static final Map<String, Future<Uint8List?>> _cache = {};

  static bool isPacked(String asset) => asset.endsWith('.bin');

  /// Çözülmüş bayt dizisini döndürür; dosya bozuksa `null`.
  static Future<Uint8List?> load(String asset) =>
      _cache.putIfAbsent(asset, () => _load(asset));

  static Future<Uint8List?> _load(String asset) async {
    try {
      final raw = (await rootBundle.load(asset)).buffer.asUint8List();
      if (raw.length < _magic.length) return null;
      for (var i = 0; i < _magic.length; i++) {
        if (raw[i] != _magic[i]) return null;
      }
      final body = raw.sublist(_magic.length);
      final n = body.length;
      final out = Uint8List(n);
      for (var i = 0; i < n; i++) {
        out[i] = body[n - 1 - i] ^ _key[i % _key.length] ^ ((i * 31) & 0xFF);
      }
      return out;
    } catch (_) {
      return null;
    }
  }
}
