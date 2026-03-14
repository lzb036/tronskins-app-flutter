import 'package:flutter/material.dart';

class HelpUi {
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius heroRadius = BorderRadius.all(Radius.circular(28));

  static Color pageBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF0D1115) : const Color(0xFFF5F7FB);
  }

  static Gradient heroGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final start = isDark
        ? Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.18),
            const Color(0xFF121821),
          )
        : Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.14),
            const Color(0xFFF7FCFD),
          );
    final end = isDark ? const Color(0xFF1B1714) : const Color(0xFFF4EBDD);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [start, end],
    );
  }

  static BorderSide cardBorder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BorderSide(
      color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.32 : 0.44),
    );
  }

  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.24),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static ShapeBorder cardShape(BuildContext context, {double radius = 20}) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: cardBorder(context),
    );
  }

  static BoxDecoration cardDecoration(
    BuildContext context, {
    Color? color,
    Gradient? gradient,
    double radius = 20,
  }) {
    return BoxDecoration(
      color: gradient == null
          ? (color ?? Theme.of(context).colorScheme.surface)
          : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.fromBorderSide(cardBorder(context)),
      boxShadow: cardShadow(context),
    );
  }

  static Color softFill(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return colorScheme.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.28 : 0.72,
    );
  }

  static InputDecoration inputDecoration(
    BuildContext context, {
    required String hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: softFill(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  static ({Color background, Color foreground}) statusColors(
    BuildContext context,
    int status,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    switch (status) {
      case 0:
        return (
          background: Colors.orange.withValues(alpha: isDark ? 0.24 : 0.14),
          foreground: isDark ? Colors.orange.shade200 : Colors.orange.shade700,
        );
      case 1:
        return (
          background: theme.colorScheme.primary.withValues(
            alpha: isDark ? 0.22 : 0.14,
          ),
          foreground: isDark
              ? const Color(0xFF9EE7F0)
              : theme.colorScheme.primary,
        );
      case 2:
        return (
          background: Colors.green.withValues(alpha: isDark ? 0.24 : 0.14),
          foreground: isDark ? Colors.green.shade200 : Colors.green.shade700,
        );
      case 3:
        return (
          background: theme.colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.26 : 0.46,
          ),
          foreground: theme.colorScheme.onSurfaceVariant,
        );
      default:
        return (
          background: theme.colorScheme.surfaceContainerHighest,
          foreground: theme.colorScheme.onSurfaceVariant,
        );
    }
  }

  static Widget statusChip(
    BuildContext context, {
    required int status,
    required String label,
  }) {
    final colors = statusColors(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
