import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  static _RestartWidgetState? _state;

  static void restartApp([BuildContext? context]) {
    final state =
        context?.findAncestorStateOfType<_RestartWidgetState>() ?? _state;
    Get.addKey(GlobalKey<NavigatorState>());
    Get.rootController.restartApp();
    state?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  @override
  void initState() {
    super.initState();
    RestartWidget._state = this;
  }

  @override
  void dispose() {
    if (RestartWidget._state == this) {
      RestartWidget._state = null;
    }
    super.dispose();
  }

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
