import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/hooks/locale/use_locale.dart';
import 'package:tronskins_app/common/hooks/theme/use_theme.dart';
import 'package:tronskins_app/common/theme/dark_theme.dart';
import 'package:tronskins_app/common/theme/light_theme.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/common/widgets/restart_widget.dart';
import 'package:tronskins_app/l10n/app_translations.dart';
import 'package:tronskins_app/routes/app_routes.dart';
import 'package:tronskins_app/routes/index.dart';

final Logger _shorebirdLogger = Logger();

Future<void> _checkForShorebirdUpdate() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  final updater = ShorebirdUpdater();
  try {
    final status = await updater.checkForUpdate();
    if (status == UpdateStatus.outdated) {
      _shorebirdLogger.i('Shorebird update available. Downloading...');
      await updater.update();
      _shorebirdLogger.i('Shorebird update downloaded. Restart to apply.');
    } else if (status == UpdateStatus.upToDate) {
      _shorebirdLogger.i('Shorebird update status: up to date.');
    } else {
      _shorebirdLogger.w('Shorebird update status unknown.');
    }
  } on UpdateException catch (error) {
    _shorebirdLogger.e('Shorebird update failed: ${error.message}');
  } catch (error) {
    _shorebirdLogger.e('Shorebird update failed: $error');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  // Init named boxes for locale/theme persistence.
  await GetStorage.init('language');
  await GetStorage.init('theme');
  await HttpHelper.init();

  // 全局持久化注入（关键！）
  Get.put(UseTheme(), permanent: true);
  Get.put(UseLocale(), permanent: true);
  final currencyController = Get.put(CurrencyController(), permanent: true);
  try {
    await currencyController
        .fetchRealRates(force: true)
        .timeout(const Duration(seconds: 5));
  } catch (_) {
    // 保持兜底汇率，避免启动卡死
  }

  runApp(const RestartWidget(child: MyApp()));
  unawaited(_checkForShorebirdUpdate());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      routingCallback: (routing) {
        if (routing == null) {
          return;
        }
        if (routing.isDialog == true || routing.isBottomSheet == true) {
          return;
        }
        if (routing.route is PageRoute || routing.removed.isNotEmpty) {
          BackToTopOverlay.reset();
        }
      },
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.noScaling),
          child: BackToTopOverlay(child: child ?? const SizedBox.shrink()),
        );
      },
      debugShowCheckedModeBanner: false,
      initialRoute: Routers.HOME,
      getPages: RoutersConfig.list,
      translations: AppTranslations(),
      fallbackLocale: const Locale('en', 'US'),

      // 动态监听主题和语言变化
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: Get.find<UseTheme>().themeMode,
      locale: Get.find<UseLocale>().currentLocale,
    );
  }
}
