// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/common/hooks/locale/use_locale.dart';
import 'package:tronskins_app/common/hooks/theme/use_theme.dart';

// ignore: use_key_in_widget_constructors
class UserSetting extends StatelessWidget {
  final Rx<Locale> currentLocale = Locale('en', 'US').obs;
  final useTheme = Get.find<UseTheme>();
  final useLocale = Get.find<UseLocale>();

  void changeLanguage(String languageCode, String countryCode) {
    final locale = Locale(languageCode, countryCode);
    Get.updateLocale(locale);
    currentLocale.value = locale;
    AppSnackbar.info('witched to ${locale.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('welcome'.tr)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('app.tabbar.home'.tr, style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text('Current Language: ${currentLocale.value.toString()}'),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.language),
              label: Text('切换语言'.tr),
              onPressed: () => useLocale.toggleLanguage(),
            ),
            SizedBox(height: 20),
            Obx(
              () => Text(
                '当前主题: ${useTheme.themeMode == ThemeMode.dark ? "暗色" : "亮色"}',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.brightness_6),
              label: Text('切换主题'.tr),
              onPressed: () => {useTheme.toggleTheme()},
            ),
          ],
        ),
      ),
    );
  }
}
