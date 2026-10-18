import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../services/safe_area_bridge.dart';

/// Tarayıcının bildirdiği güvenli alanı (iPhone'da ana ekran çizgisi,
/// çentik) MediaQuery'nin padding/viewPadding değerine ekler; böylece
/// SafeArea ve alt sekme çubuğu web'de de doğru yere oturur. Döndürme ve
/// pencere değişiminde yeniden ölçer.
class WebSafeArea extends StatefulWidget {
  const WebSafeArea({super.key, required this.child, this.read = webSafeArea});

  final Widget child;
  final EdgeInsets Function() read;

  @override
  State<WebSafeArea> createState() => _WebSafeAreaState();
}

class _WebSafeAreaState extends State<WebSafeArea> with WidgetsBindingObserver {
  late EdgeInsets _insets = widget.read();
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _settle?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _measure() {
    final next = widget.read();
    if (next != _insets && mounted) setState(() => _insets = next);
  }

  @override
  void didChangeMetrics() {
    _measure();
    // iOS env() değerleri döndürmeden biraz sonra güncellenir.
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 350), _measure);
  }

  @override
  Widget build(BuildContext context) {
    if (_insets == EdgeInsets.zero) return widget.child;
    final mq = MediaQuery.of(context);
    EdgeInsets merge(EdgeInsets a) => EdgeInsets.fromLTRB(
          math.max(a.left, _insets.left),
          math.max(a.top, _insets.top),
          math.max(a.right, _insets.right),
          math.max(a.bottom, _insets.bottom),
        );
    // Klavye açıkken alt boşluk klavyenin içinde kalır.
    final padding = merge(mq.padding);
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.viewInsets.bottom > 0
            ? padding.copyWith(bottom: mq.padding.bottom)
            : padding,
        viewPadding: merge(mq.viewPadding),
      ),
      child: widget.child,
    );
  }
}
