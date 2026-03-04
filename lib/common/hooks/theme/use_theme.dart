import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UseTheme extends GetxController {
  static final _storage = GetStorage('theme');
  final Rx<ThemeMode> _themeMode = ThemeMode.light.obs;

  ThemeMode get themeMode => _themeMode.value;

  // 预定义主题
  final lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),
  );

  final darkTheme = ThemeData(
    primarySwatch: Colors.deepPurple,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(backgroundColor: Colors.deepPurple[900]),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.deepPurple,
    ),
  );

  @override
  void onInit() {
    super.onInit();
    // 从存储加载主题模式
    final savedThemeMode = _storage.read<String>('themeMode');
    _loadThemeMode(savedThemeMode);
  }

  void _loadThemeMode(String? themeModeKey) {
    switch (themeModeKey) {
      case 'light':
        _themeMode.value = ThemeMode.light;
        break;
      case 'dark':
        _themeMode.value = ThemeMode.dark;
        break;
      case 'system':
        _themeMode.value = ThemeMode.system;
        break;
      default:
        _themeMode.value = ThemeMode.light;
    }
  }

  void toggleTheme() {
    ThemeMode newThemeMode;

    // 根据当前主题模式决定切换到哪个主题
    if (_themeMode.value == ThemeMode.light) {
      newThemeMode = ThemeMode.dark;
    } else if (_themeMode.value == ThemeMode.dark) {
      newThemeMode = ThemeMode.light;
    } else {
      // 如果当前是系统主题，则根据当前实际主题切换
      // ignore: deprecated_member_use
      final isDark =
          WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
      newThemeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    }

    _themeMode.value = newThemeMode;
    Get.changeThemeMode(newThemeMode);

    // 保存设置
    String modeString;
    switch (newThemeMode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      default:
        modeString = 'system';
    }

    _storage.write('themeMode', modeString);
    update();
  }

  void changeThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);

    // 保存设置
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      default:
        modeString = 'system';
    }

    _storage.write('themeMode', modeString);
    update();
  }
}
