import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/theme/app_colors.dart';

/// Centralized top snackbar with a game-trading visual treatment.
class AppSnackbar {
  AppSnackbar._();

  /// Shows a success snackbar.
  static void success(String message, {String? title}) {
    _show(message: message, title: title, variant: _AppSnackbarVariant.success);
  }

  /// Shows an error snackbar.
  static void error(String message, {String? title}) {
    _show(message: message, title: title, variant: _AppSnackbarVariant.error);
  }

  /// Shows a neutral snackbar.
  static void neutral(String message, {String? title}) {
    _show(message: message, title: title, variant: _AppSnackbarVariant.neutral);
  }

  /// Alias for neutral informational messages.
  static void info(String message, {String? title}) {
    neutral(message, title: title);
  }

  static void _show({
    required String message,
    String? title,
    required _AppSnackbarVariant variant,
  }) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return;
    }

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    final resolvedTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : 'app.system.tips.title'.tr;

    Get.showSnackbar(
      GetSnackBar(
        messageText: _GameTradeSnackbarCard(
          title: resolvedTitle,
          message: trimmedMessage,
          variant: variant,
        ),
        backgroundColor: Colors.transparent,
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        borderRadius: 0,
        duration: const Duration(milliseconds: 2600),
        animationDuration: const Duration(milliseconds: 320),
        forwardAnimationCurve: Curves.easeOutCubic,
        reverseAnimationCurve: Curves.easeInCubic,
        isDismissible: true,
      ),
    );
  }
}

enum _AppSnackbarVariant { success, error, neutral }

class _GameTradeSnackbarCard extends StatelessWidget {
  const _GameTradeSnackbarCard({
    required this.title,
    required this.message,
    required this.variant,
  });

  final String title;
  final String message;
  final _AppSnackbarVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors =
        theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light);
    final style = _AppSnackbarStyle.resolve(variant, appColors);

    final titleStyle = theme.textTheme.labelMedium?.copyWith(
      color: style.titleColor,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );
    final messageStyle = theme.textTheme.bodyMedium?.copyWith(
      color: style.messageColor,
      fontWeight: FontWeight.w600,
      height: 1.35,
    );
    final badgeStyle = theme.textTheme.labelSmall?.copyWith(
      color: style.badgeTextColor,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.9,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [style.surfaceStart, style.surfaceEnd],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: style.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: style.glowColor,
                      blurRadius: 20,
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              style.accentColor,
                              style.accentColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -30,
                      right: -18,
                      child: IgnorePointer(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                style.accentColor.withValues(alpha: 0.24),
                                style.accentColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IconBadge(style: style),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: titleStyle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: style.badgeBackgroundColor,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: style.badgeBorderColor,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        child: Text(
                                          style.badgeLabel,
                                          style: badgeStyle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  message,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: messageStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.style});

  final _AppSnackbarStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.iconBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.iconBorderColor),
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(style.icon, color: style.accentColor, size: 22),
      ),
    );
  }
}

class _AppSnackbarStyle {
  const _AppSnackbarStyle({
    required this.icon,
    required this.badgeLabel,
    required this.accentColor,
    required this.surfaceStart,
    required this.surfaceEnd,
    required this.borderColor,
    required this.glowColor,
    required this.titleColor,
    required this.messageColor,
    required this.badgeTextColor,
    required this.badgeBackgroundColor,
    required this.badgeBorderColor,
    required this.iconBackgroundColor,
    required this.iconBorderColor,
  });

  final IconData icon;
  final String badgeLabel;
  final Color accentColor;
  final Color surfaceStart;
  final Color surfaceEnd;
  final Color borderColor;
  final Color glowColor;
  final Color titleColor;
  final Color messageColor;
  final Color badgeTextColor;
  final Color badgeBackgroundColor;
  final Color badgeBorderColor;
  final Color iconBackgroundColor;
  final Color iconBorderColor;

  factory _AppSnackbarStyle.resolve(
    _AppSnackbarVariant variant,
    AppColors colors,
  ) {
    const baseStart = Color(0xF2192330);
    const baseEnd = Color(0xF20B1016);

    late final Color accent;
    late final IconData icon;
    late final String badgeLabel;

    switch (variant) {
      case _AppSnackbarVariant.success:
        accent = colors.success;
        icon = Icons.task_alt_rounded;
        badgeLabel = 'SUCCESS';
        break;
      case _AppSnackbarVariant.error:
        accent = colors.danger;
        icon = Icons.gpp_bad_rounded;
        badgeLabel = 'FAILED';
        break;
      case _AppSnackbarVariant.neutral:
        accent = colors.primary;
        icon = Icons.notifications_active_rounded;
        badgeLabel = 'NOTICE';
        break;
    }

    return _AppSnackbarStyle(
      icon: icon,
      badgeLabel: badgeLabel,
      accentColor: accent,
      surfaceStart: Color.lerp(baseStart, accent, 0.16)!,
      surfaceEnd: Color.lerp(baseEnd, accent, 0.05)!,
      borderColor: accent.withValues(alpha: 0.34),
      glowColor: accent.withValues(alpha: 0.16),
      titleColor: accent.withValues(alpha: 0.96),
      messageColor: Colors.white.withValues(alpha: 0.92),
      badgeTextColor: accent.withValues(alpha: 0.96),
      badgeBackgroundColor: accent.withValues(alpha: 0.14),
      badgeBorderColor: accent.withValues(alpha: 0.24),
      iconBackgroundColor: accent.withValues(alpha: 0.14),
      iconBorderColor: accent.withValues(alpha: 0.26),
    );
  }
}
