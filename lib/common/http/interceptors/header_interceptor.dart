// lib/common/http/interceptors/header_interceptor.dart
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/hooks/locale/use_locale.dart';
import 'package:tronskins_app/common/storage/session_storage.dart';

class HeaderInterceptor extends Interceptor {
  static const String _refreshEndpoint = 'api/app/auth/refresh';

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
      final cookiePairs = <String>['locale=$localeTag'];
      final authCookies = SessionStorage.getAuthCookies();
      final webId = SessionStorage.getWebId();
      if (webId != null && webId.isNotEmpty) {
        authCookies.putIfAbsent('WEBID', () => webId);
        authCookies.putIfAbsent('JSESSIONID', () => webId);
        authCookies.putIfAbsent('JSESSIONI', () => webId);
      }
      final orderedKeys = <String>[
        'WEBID',
        'JSESSIONID',
        'JSESSIONI',
        'refresh_token',
      ];
      final includeRefreshCookie =
          options.extra['include_refresh_cookie'] == true ||
          _isRefreshRequest(options.path);
      for (final key in orderedKeys) {
        if (key == 'refresh_token' && !includeRefreshCookie) {
          continue;
        }
        final value = authCookies[key];
        if (value == null || value.isEmpty) {
          continue;
        }
        cookiePairs.add('$key=$value');
      }
      options.headers['Cookie'] = '${cookiePairs.join(';')};';
    }

    super.onRequest(options, handler);
  }

  bool _isRefreshRequest(String path) {
    final normalized = _normalizePath(path);
    return normalized.contains(_refreshEndpoint);
  }

  String _normalizePath(String path) {
    var normalized = path.trim();
    if (normalized.startsWith('http')) {
      normalized = Uri.parse(normalized).path;
    }
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }
}
