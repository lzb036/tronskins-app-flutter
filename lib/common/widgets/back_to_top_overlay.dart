import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  bool _isRouteEnabled() {
    return !widget.excludeRoutes.contains(Get.currentRoute);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_isRouteEnabled()) {
      return false;
    }
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical || metrics.maxScrollExtent <= 0) {
      return false;
    }

    final notificationContext = notification.context;
    if (notificationContext != null) {
      final scrollable = Scrollable.maybeOf(notificationContext);
      if (scrollable != null) {
        _activePosition = scrollable.position;
      }
    }

    final shouldShow = metrics.pixels > widget.threshold;
    if (shouldShow != _visible.value) {
      _visible.value = shouldShow;
    }
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
    _visible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;
    if (currentRoute != _lastRoute) {
      _lastRoute = currentRoute;
      _activePosition = null;
      if (_visible.value) {
        _visible.value = false;
      }
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

    return NotificationListener<ScrollNotification>(
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
    );
  }
}
