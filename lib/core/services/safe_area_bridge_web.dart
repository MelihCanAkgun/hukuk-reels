import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';

@JS('hukukSafeArea')
external JSString? _read();

/// web/pwa.js'nin ölçtüğü iOS güvenli alan boşlukları (mantıksal piksel).
EdgeInsets webSafeArea() {
  try {
    final raw = _read()?.toDart;
    if (raw == null) return EdgeInsets.zero;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    double v(String k) => (m[k] as num?)?.toDouble() ?? 0;
    return EdgeInsets.fromLTRB(v('left'), v('top'), v('right'), v('bottom'));
  } catch (_) {
    return EdgeInsets.zero;
  }
}
