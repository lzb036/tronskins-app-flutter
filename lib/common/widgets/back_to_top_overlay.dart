import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/controllers/navbar/nav_controller.dart';

/// Scope switch for back-to-top visibility handling.
///
/// Use `enabled: false` to disable back-to-top for a subtree. A nested scope
/// can re-enable it for specific descendant list areas.
class BackToTopScope extends InheritedWidget {
  const BackToTopScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static bool isEnabled(BuildContext? context, {bool fallback = true}) {
    if (context == null) {
      return fallback;
    }
    final element = context
        .getElementForInheritedWidgetOfExactType<BackToTopScope>();
    final scope = element?.widget as BackToTopScope?;
    return scope?.enabled ?? fallback;
  }

  @override
  bool updateShouldNotify(BackToTopScope oldWidget) {
    return oldWidget.enabled != enabled;
  }
}

/// Global back-to-top overlay driven by scroll notifications.
/// It can be wrapped at app level to reuse across all list pages.
class BackToTopOverlay extends StatefulWidget {
  const BackToTopOverlay({
    super.key,
    required this.child,
    this.threshold = 100,
    this.excludeRoutes = const <String>{},
  });

  final Widget child;
  final double threshold;
  final Set<String> excludeRoutes;

  @override
  State<BackToTopOverlay> createState() => _BackToTopOverlayState();
}

class _BackToTopOverlayState extends State<BackToTopOverlay> {
  final ValueNotifier<bool> _visible = ValueNotifier<bool>(false);
  ScrollPosition? _activePosition;
  String? _lastRoute;
  int? _lastNavIndex;
  Worker? _navWorker;
  bool _navBindingScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleNavBinding();
  }

  bool _isRouteEnabled() {
    return !widget.excludeRoutes.contains(Get.currentRoute);
  }

  void _resetOverlayState() {
    _activePosition = null;
    if (_visible.value) {
      _visible.value = false;
    }
  }

  void _bindNavController() {
    if (!mounted || _navWorker != null || !Get.isRegistered<NavController>()) {
      return;
    }
    final navController = Get.find<NavController>();
    _lastNavIndex = navController.currentIndex.value;
    _navWorker = ever<int>(navController.currentIndex, (index) {
      if (_lastNavIndex == index) {
        return;
      }
      _lastNavIndex = index;
      _resetOverlayState();
    });
  }

  void _scheduleNavBinding() {
    if (!mounted || _navWorker != null || _navBindingScheduled) {
      return;
    }
    _navBindingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navBindingScheduled = false;
      if (!mounted || _navWorker != null) {
        return;
      }
      if (Get.isRegistered<NavController>()) {
        _bindNavController();
        return;
      }
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        _scheduleNavBinding();
      });
    });
  }

  void _updateActivePosition(BuildContext? notificationContext) {
    if (notificationContext == null) {
      return;
    }
    final scrollable = Scrollable.maybeOf(notificationContext);
    if (scrollable == null) {
      return;
    }
    _activePosition = scrollable.position;
  }

  void _syncVisibilityByMetrics(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical) {
      return;
    }
    final shouldShow =
        metrics.maxScrollExtent > 0 && metrics.pixels > widget.threshold;
    if (shouldShow != _visible.value) {
      _visible.value = shouldShow;
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_isRouteEnabled()) {
      return false;
    }
    if (!BackToTopScope.isEnabled(notification.context, fallback: true)) {
      _resetOverlayState();
      return false;
    }
    _updateActivePosition(notification.context);
    _syncVisibilityByMetrics(notification.metrics);
    return false;
  }

  bool _handleScrollMetricsNotification(
    ScrollMetricsNotification notification,
  ) {
    if (!_isRouteEnabled()) {
      return false;
    }
    if (!BackToTopScope.isEnabled(notification.context, fallback: true)) {
      _resetOverlayState();
      return false;
    }
    _updateActivePosition(notification.context);
    _syncVisibilityByMetrics(notification.metrics);
    return false;
  }

  Future<void> _scrollToTop() async {
    final position = _activePosition;
    if (position == null) {
      return;
    }
    try {
      await position.animateTo(
        0,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeInOutCubic,
      );
    } catch (_) {
      // Ignore when position gets detached during route changes.
    }
  }

  @override
  void dispose() {
    _navWorker?.dispose();
    _visible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;
    if (currentRoute != _lastRoute) {
      _lastRoute = currentRoute;
      _resetOverlayState();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? colorScheme.surface.withValues(alpha: 0.76)
        : Colors.white.withValues(alpha: 0.88);
    final borderColor = colorScheme.outline.withValues(
      alpha: isDark ? 0.34 : 0.18,
    );
    final iconColor = colorScheme.onSurface.withValues(alpha: 0.82);

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleScrollMetricsNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            ValueListenableBuilder<bool>(
              valueListenable: _visible,
              builder: (context, showBackToTop, child) {
                final routeEnabled = _isRouteEnabled();
                final visible = routeEnabled && showBackToTop;
                final bottomPadding = currentRoute == '/' ? 72.0 : 12.0;

                return SafeArea(
                  minimum: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: IgnorePointer(
                      ignoring: !visible,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        offset: visible ? Offset.zero : const Offset(0, 0.35),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          opacity: visible ? 1 : 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.18 : 0.10,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                onTap: _scrollToTop,
                                borderRadius: BorderRadius.circular(999),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: Icon(
                                    Icons.keyboard_double_arrow_up_rounded,
                                    size: 20,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
