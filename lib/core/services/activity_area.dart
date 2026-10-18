import 'dart:async';

import 'package:flutter/widgets.dart';

import 'social_bridge.dart';

/// Uygulamanın hangi bölümünde olunduğunu (en üstteki ekran) web katmanına
/// bildirir; süre, yöneticinin Aktiflik ekranında bölüm bölüm görünür.
/// Sunucuya ayrıca istek atılmaz: bölüm bir sonraki "son görülme"
/// bildirimiyle gider (bkz. web/social.js).
class ActivityArea {
  ActivityArea._();
  static final ActivityArea instance = ActivityArea._();

  final List<Object> _stack = [];
  final Map<Object, String> _areas = {};
  String? _sent;

  /// Testlerde sahte köprü bağlamak için.
  @visibleForTesting
  Future<Map<String, dynamic>> Function(String action,
      [Map<String, dynamic> data]) call = socialCall;

  /// En son açılmış ve hâlâ ekranda olan bölüm.
  String get current => _stack.isEmpty ? 'other' : _areas[_stack.last]!;

  void enter(Object owner, String area) {
    _stack.remove(owner);
    _stack.add(owner);
    _areas[owner] = area;
    _report();
  }

  void leave(Object owner) {
    _stack.remove(owner);
    _areas.remove(owner);
    _report();
  }

  void _report() {
    final area = current;
    if (area == _sent) return;
    _sent = area;
    unawaited(call('area', {'area': area}));
  }

  @visibleForTesting
  void reset() {
    _stack.clear();
    _areas.clear();
    _sent = null;
  }
}

/// Altındaki ekranı [area] bölümü olarak işaretler (ekran açıkken).
class ActivityAreaScope extends StatefulWidget {
  const ActivityAreaScope({super.key, required this.area, required this.child});

  final String area;
  final Widget child;

  @override
  State<ActivityAreaScope> createState() => _ActivityAreaScopeState();
}

class _ActivityAreaScopeState extends State<ActivityAreaScope> {
  @override
  void initState() {
    super.initState();
    ActivityArea.instance.enter(this, widget.area);
  }

  @override
  void didUpdateWidget(ActivityAreaScope old) {
    super.didUpdateWidget(old);
    if (old.area != widget.area) ActivityArea.instance.enter(this, widget.area);
  }

  @override
  void dispose() {
    ActivityArea.instance.leave(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
