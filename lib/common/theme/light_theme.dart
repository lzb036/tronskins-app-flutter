import 'package:flutter/material.dart';
import 'package:tronskins_app/common/theme/app_colors.dart';
import 'package:tronskins_app/common/theme/app_text_theme.dart';

ThemeData lightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.light.primary),
  scaffoldBackgroundColor: AppColors.light.scaffoldBackground,
  splashFactory: InkSparkle.splashFactory,
  extensions: [AppColors.light, AppTextTheme.light()],
);
