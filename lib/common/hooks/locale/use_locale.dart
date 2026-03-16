import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UseLocale extends GetxController {
  static final _storage = GetStorage('language');
  static const Locale _defaultLocale = Locale('en', 'US');

  final Rx<Locale> _currentLocale = _defaultLocale.obs;

  Locale get currentLocale => _currentLocale.value;
  Rx<Locale> get localeRx => _currentLocale;

  // 支持的语言列表
  final List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'country': 'US', 'name': 'English', 'icon': 'en_US'},
    {
      'code': 'zh',
      'country': 'CN',
      'name': 'Chinese (Simplified)',
      'icon': 'zh_CN',
    },
    {
      'code': 'zh',
      'country': 'HK',
      'name': 'Chinese (Traditional)',
      'icon': 'zh_HK',
    },
    {'code': 'fr', 'country': 'FR', 'name': 'French', 'icon': 'fr_FR'},
    {'code': 'ge', 'country': 'DE', 'name': 'German', 'icon': 'ge_DE'},
    {'code': 'de', 'country': 'DE', 'name': 'German (Alt)', 'icon': 'ge_DE'},
    {'code': 'in', 'country': 'ID', 'name': 'Indonesian', 'icon': 'in_ID'},
    {'code': 'it', 'country': 'IT', 'name': 'Italian', 'icon': 'it_IT'},
    {'code': 'ja', 'country': 'JP', 'name': 'Japanese', 'icon': 'ja_JP'},
    {'code': 'ko', 'country': 'KR', 'name': 'Korean', 'icon': 'ko_KR'},
    {'code': 'la', 'country': 'LAT', 'name': 'Latin', 'icon': 'la_LAT'},
    {'code': 'po', 'country': 'PL', 'name': 'Polish', 'icon': 'po_PL'},
    {'code': 'po', 'country': 'PT', 'name': 'Portuguese', 'icon': 'po_PT'},
    {'code': 'ru', 'country': 'RU', 'name': 'Russian', 'icon': 'ru_RU'},
    {'code': 'sp', 'country': 'ES', 'name': 'Spanish', 'icon': 'sp_ES'},
    {'code': 'th', 'country': 'TH', 'name': 'Thai', 'icon': 'th_TH'},
    {'code': 'tu', 'country': 'TR', 'name': 'Turkish', 'icon': 'tu_TR'},
    {'code': 'vi', 'country': 'VN', 'name': 'Vietnamese', 'icon': 'vi_VN'},
  ];

  @override
  void onInit() {
    super.onInit();
    // 从存储加载语言设置
    final savedLanguageCode = _storage.read<String>('languageCode');
    final savedCountryCode = _storage.read<String>('countryCode');

    if (savedLanguageCode != null && savedCountryCode != null) {
      _currentLocale.value = Locale(savedLanguageCode, savedCountryCode);
    } else {
      // 没有用户显式选择时，应用默认使用英文。
      _currentLocale.value = _defaultLocale;
    }
  }

  void changeLanguage(String languageCode, String countryCode) {
    final locale = Locale(languageCode, countryCode);
    _currentLocale.value = locale;

    // 更新应用语言
    Get.updateLocale(locale);

    // 保存设置
    _storage.write('languageCode', languageCode);
    _storage.write('countryCode', countryCode);

    update();
  }

  void toggleLanguage() {
    final current = _currentLocale.value;

    // 在支持的语言之间切换
    if (current.languageCode == 'en') {
      changeLanguage('zh', 'CN');
    } else if (current.languageCode == 'zh') {
      changeLanguage('en', 'US');
    } else {
      // 默认切换到英语
      changeLanguage('en', 'US');
    }
  }

  String getLanguageName(Locale locale) {
    // 使用翻译键获取语言自己的文字
    final localeKey = '${locale.languageCode}_${locale.countryCode}';
    final key = 'app.system.language.$localeKey';
    final translated = key.tr;
    if (translated == key) {
      if (localeKey == 'zh_HK') {
        return 'app.system.language.zh_TW'.tr;
      }
      return localeKey;
    }
    return translated;
  }

  // 获取本地化的语言名称（用于显示在语言列表中）
  String getLocalizedLanguageName(Map<String, String> lang) {
    final code = lang['code'] ?? '';
    final country = lang['country'] ?? '';
    final localeKey = '${code}_$country';

    // 使用翻译键来显示语言自己的文字
    final key = 'app.system.language.$localeKey';
    final translated = key.tr;
    if (translated == key) {
      if (localeKey == 'zh_HK') {
        return 'app.system.language.zh_TW'.tr;
      }
      return lang['name'] ?? localeKey;
    }
    return translated;
  }

  // 获取语言图标路径
  String getLanguageIcon(Map<String, String> lang) {
    final icon = lang['icon'] ?? '';
    return 'assets/images/lang/$icon.png';
  }

  // 获取当前语言的图标路径
  String getCurrentLanguageIcon() {
    for (var lang in supportedLanguages) {
      if (lang['code'] == _currentLocale.value.languageCode &&
          lang['country'] == _currentLocale.value.countryCode) {
        return getLanguageIcon(lang);
      }
    }
    return 'assets/images/lang/en_US.png';
  }
}
