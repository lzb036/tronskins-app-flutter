// lib/common/theme/theme_text.dart

import 'package:flutter/material.dart';

/// 全局字体大小管理（推荐使用 Material 3 标准值 + 轻微调整）
class AppTextSizes {
  const AppTextSizes._();

  // Display（超大标题，几乎不用）
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;

  // Headline（页面主标题）
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;

  // Title（组件标题、卡片标题）
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0; // 常用
  static const double titleSmall = 16.0;

  // Body（正文）
  static const double bodyLarge = 16.0; // 主要正文
  static const double bodyMedium = 14.0; // 辅助说明
  static const double bodySmall = 12.0; // 极小提示

  // Label（按钮、标签、表单标签）
  static const double labelLarge = 14.0; // 按钮文字
  static const double labelMedium = 12.0; // Tab、Chip
  static const double labelSmall = 11.0; // 极小标签
}

/// 可扩展的字体配置（支持动态文本缩放 + 深浅色自动适配）
class AppTextTheme extends ThemeExtension<AppTextTheme> {
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;

  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;

  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;

  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;

  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;

  const AppTextTheme({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });

  // 浅色模式文本主题
  static AppTextTheme light([String fontFamily = 'Roboto']) {
    return AppTextTheme(
      displayLarge: TextStyle(
        fontSize: AppTextSizes.displayLarge,
        fontWeight: FontWeight.w400,
        height: 1.2,
        letterSpacing: -0.5,
        fontFamily: fontFamily,
      ),
      displayMedium: TextStyle(
        fontSize: AppTextSizes.displayMedium,
        fontWeight: FontWeight.w400,
        height: 1.2,
        letterSpacing: -0.25,
        fontFamily: fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: AppTextSizes.displaySmall,
        fontWeight: FontWeight.w400,
        height: 1.3,
        fontFamily: fontFamily,
      ),

      headlineLarge: TextStyle(
        fontSize: AppTextSizes.headlineLarge,
        fontWeight: FontWeight.w600,
        height: 1.3,
        fontFamily: fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: AppTextSizes.headlineMedium,
        fontWeight: FontWeight.w600,
        height: 1.3,
        fontFamily: fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: AppTextSizes.headlineSmall,
        fontWeight: FontWeight.w600,
        height: 1.35,
        fontFamily: fontFamily,
      ),

      titleLarge: TextStyle(
        fontSize: AppTextSizes.titleLarge,
        fontWeight: FontWeight.w600,
        height: 1.4,
        fontFamily: fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: AppTextSizes.titleMedium,
        fontWeight: FontWeight.w600,
        height: 1.4,
        fontFamily: fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: AppTextSizes.titleSmall,
        fontWeight: FontWeight.w500,
        height: 1.4,
        fontFamily: fontFamily,
      ),

      bodyLarge: TextStyle(
        fontSize: AppTextSizes.bodyLarge,
        fontWeight: FontWeight.w400,
        height: 1.6,
        fontFamily: fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: AppTextSizes.bodyMedium,
        fontWeight: FontWeight.w400,
        height: 1.5,
        fontFamily: fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: AppTextSizes.bodySmall,
        fontWeight: FontWeight.w400,
        height: 1.5,
        fontFamily: fontFamily,
      ),

      labelLarge: TextStyle(
        fontSize: AppTextSizes.labelLarge,
        fontWeight: FontWeight.w600,
        height: 1.4,
        fontFamily: fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: AppTextSizes.labelMedium,
        fontWeight: FontWeight.w500,
        height: 1.4,
        fontFamily: fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: AppTextSizes.labelSmall,
        fontWeight: FontWeight.w500,
        height: 1.4,
        fontFamily: fontFamily,
      ),
    );
  }

  // 深色模式（颜色自动适配，字号不变）
  static AppTextTheme dark([String fontFamily = 'Roboto']) => light(fontFamily);

  @override
  AppTextTheme copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
  }) {
    return AppTextTheme(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
    );
  }

  @override
  AppTextTheme lerp(ThemeExtension<AppTextTheme>? other, double t) {
    if (other is! AppTextTheme) return this;
    return AppTextTheme(
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t)!,
      displaySmall: TextStyle.lerp(displaySmall, other.displaySmall, t)!,
      headlineLarge: TextStyle.lerp(headlineLarge, other.headlineLarge, t)!,
      headlineMedium: TextStyle.lerp(headlineMedium, other.headlineMedium, t)!,
      headlineSmall: TextStyle.lerp(headlineSmall, other.headlineSmall, t)!,
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t)!,
      titleMedium: TextStyle.lerp(titleMedium, other.titleMedium, t)!,
      titleSmall: TextStyle.lerp(titleSmall, other.titleSmall, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      labelLarge: TextStyle.lerp(labelLarge, other.labelLarge, t)!,
      labelMedium: TextStyle.lerp(labelMedium, other.labelMedium, t)!,
      labelSmall: TextStyle.lerp(labelSmall, other.labelSmall, t)!,
    );
  }
}
