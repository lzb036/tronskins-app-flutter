// lib/common/http/interceptors/header_interceptor.dart
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/hooks/locale/use_locale.dart';
import 'package:tronskins_app/common/storage/session_storage.dart';

class HeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 公共 header
    options.headers['App-Type'] = 'app';
    options.headers['Platform'] = GetPlatform.isAndroid ? 'android' : 'ios';

    // 语言
    final locale = Get.find<UseLocale>().currentLocale;
    options.headers['Accept-Language'] =
        '${locale.languageCode}-${locale.countryCode}';

    final localeTag = locale.countryCode == null
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
    final skipCookie = options.extra['skip_cookie'] == true;
    if (!skipCookie) {
      final webId = SessionStorage.getWebId();
      final cookies = <String>['locale=$localeTag'];
      if (webId != null && webId.isNotEmpty) {
        // 兼容历史后端：JSESSIONI
        cookies.add('JSESSIONI=$webId');
        // 兼容标准命名：JSESSIONID
        cookies.add('JSESSIONID=$webId');
        // 兼容后端直接读取 WEBID
        cookies.add('WEBID=$webId');
      }
      options.headers['Cookie'] = '${cookies.join(';')};';
    }

    super.onRequest(options, handler);
  }
}
