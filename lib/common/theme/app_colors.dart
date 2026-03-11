// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// 全局颜色管理（推荐放在 lib/core/theme/ 下）
class AppColors extends ThemeExtension<AppColors> {
  // 主色调
  final Color primary; // 品牌色：霓虹蓝
  final Color onPrimary; // 主色上的文字/图标

  // 功能色
  final Color danger;
  final Color onDanger;
  final Color success;
  final Color onSuccess;
  final Color info;
  final Color onInfo;

  // 文字颜色
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color textPlaceholder;

  // 背景颜色
  final Color background;
  final Color surface; // 卡片、对话框等浮动表面
  final Color surfaceVariant; // 次级表面
  final Color scaffoldBackground;

  // 边框与分割线
  final Color border;
  final Color divider;

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.danger,
    required this.onDanger,
    required this.success,
    required this.onSuccess,
    required this.info,
    required this.onInfo,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textPlaceholder,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.scaffoldBackground,
    required this.border,
    required this.divider,
  });

  // 浅色模式配色（推荐直接用 Material 3 推荐值 + 你的品牌色）
  static const AppColors light = AppColors(
    primary: Color(0xFF00B4CC),
    onPrimary: Colors.white,
    danger: Color(0xFFFF4D00),
    onDanger: Colors.white,
    success: Color(0xFF439143),
    onSuccess: Colors.white,
    info: Color(0xFF2A3B4D),
    onInfo: Colors.white,
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF757575),
    textDisabled: Color(0xFF9E9E9E),
    textPlaceholder: Color(0xFFBDBDBD),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFAFAFA),
    surfaceVariant: Color(0xFFF5F5F5),
    scaffoldBackground: Color(0xFFF8F9FA),
    border: Color(0xFFE0E0E0),
    divider: Color(0xFFEEEEEE),
  );

  // 深色模式配色（完美适配 OLED 屏）
  static const AppColors dark = AppColors(
    primary: Color(0xFF00D4F0), // 亮一点的霓虹蓝，更有活力
    onPrimary: Colors.black87,
    danger: Color(0xFFFF6B4D),
    onDanger: Colors.white,
    success: Color(0xFF66BB6A),
    onSuccess: Colors.black87,
    info: Color(0xFF455A64),
    onInfo: Colors.white,
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFFB0B0B0),
    textDisabled: Color(0xFF777777),
    textPlaceholder: Color(0xFF555555),
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF272626),
    scaffoldBackground: Color(0xFF000000),
    border: Color(0xFF2A3B4D),
    divider: Color(0xFF333333),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? danger,
    Color? onDanger,
    Color? success,
    Color? onSuccess,
    Color? info,
    Color? onInfo,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? textPlaceholder,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? scaffoldBackground,
    Color? border,
    Color? divider,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      border: border ?? this.border,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textPlaceholder: Color.lerp(textPlaceholder, other.textPlaceholder, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      scaffoldBackground: Color.lerp(
        scaffoldBackground,
        other.scaffoldBackground,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
