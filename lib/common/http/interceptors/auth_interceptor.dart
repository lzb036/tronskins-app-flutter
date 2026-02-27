// lib/common/http/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:tronskins_app/common/security/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  static String? _token;
  static const String _tokenKey = 'auth_token';

  // 读取本地 token（程序启动时调用）
  static Future<void> loadTokenFromStorage() async {
    _token = await SecureStorage.getItem(_tokenKey);
  }

  static Future<void> setToken(String token) async {
    _token = token;
    await SecureStorage.setItem(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    _token = null;
    await SecureStorage.removeItem(_tokenKey);
  }

  static bool get hasToken => _token != null && _token!.isNotEmpty;
  static String? get token => _token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_token != null && _token!.isNotEmpty) {
      final useRawAuthorization = options.extra['raw_authorization'] == true;
      if (useRawAuthorization) {
        options.headers['Authorization'] = _token;
      } else {
        options.headers['Authorization'] = 'Bearer $_token';
      }
      // 或者你的后端用的是下面这种（根据实际改）
      // options.headers['token'] = _token;
    }
    super.onRequest(options, handler);
  }
}
