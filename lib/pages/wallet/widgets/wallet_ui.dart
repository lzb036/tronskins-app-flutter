import 'package:flutter/material.dart';

class WalletUi {
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(18));

  static Color pageBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF0F1218) : const Color(0xFFF4F6FB);
  }

  static LinearGradient primaryGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: [
        colorScheme.primary.withValues(alpha: isDark ? 0.72 : 0.9),
        colorScheme.secondary.withValues(alpha: isDark ? 0.5 : 0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static List<BoxShadow> gradientShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const [];
    }
    return [
      BoxShadow(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static BorderSide cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BorderSide(
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
    );
  }

  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const [];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static ShapeBorder cardShape(BuildContext context) {
    return RoundedRectangleBorder(
      borderRadius: cardRadius,
      side: cardBorder(context),
    );
  }

  static BoxDecoration cardDecoration(BuildContext context, {Color? color}) {
    return BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: cardRadius,
      border: Border.fromBorderSide(cardBorder(context)),
      boxShadow: cardShadow(context),
    );
  }

  static InputDecoration inputDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
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
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
