import 'package:flutter/material.dart';
import 'package:tronskins_app/common/theme/app_colors.dart';
import 'package:tronskins_app/common/theme/app_text_theme.dart';

ThemeData darkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.dark.primary, brightness: Brightness.dark),
  scaffoldBackgroundColor: AppColors.dark.scaffoldBackground,
  splashFactory: InkSparkle.splashFactory,
  extensions: [AppColors.dark, AppTextTheme.dark()],
);