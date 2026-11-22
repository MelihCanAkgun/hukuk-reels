import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hukuk_reels/core/utils/packed_asset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final name in ['k2.bin', 'k3.bin']) {
    test('$name decodes to a JPEG', () async {
      final bytes = await PackedAsset.load('assets/images/$name');
      expect(bytes, isNotNull);
      expect(bytes!.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
      expect(bytes.sublist(bytes.length - 2), [0xFF, 0xD9]);
      expect(bytes.length, File('assets/images/$name').lengthSync() - 4);
    });
  }
}
