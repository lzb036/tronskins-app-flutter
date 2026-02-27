import 'package:dio/dio.dart';
import 'package:tronskins_app/common/storage/session_storage.dart';

class CookieInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _syncWebId(response);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _syncWebId(err.response);
    super.onError(err, handler);
  }

  void _syncWebId(Response<dynamic>? response) {
    if (response == null) return;
    final cookies =
        response.headers['set-cookie'] ??
        response.headers['Set-Cookie'] ??
        <String>[];
    if (cookies.isEmpty) return;

    final webId = _extractWebId(cookies);
    if (webId == null || webId.isEmpty) return;

    final current = SessionStorage.getWebId();
    if (current == null ||
        current.isEmpty ||
        current.length < 32 ||
        current != webId) {
      SessionStorage.setWebId(webId);
    }
  }

  String? _extractWebId(List<String> cookies) {
    String? sessionId;
    for (final cookie in cookies) {
      final parts = cookie.split(';');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.startsWith('WEBID=')) {
          return trimmed.substring('WEBID='.length);
        }
        if (sessionId == null && trimmed.startsWith('JSESSIONID=')) {
          sessionId = trimmed.substring('JSESSIONID='.length);
        }
        if (sessionId == null && trimmed.startsWith('JSESSIONI=')) {
          sessionId = trimmed.substring('JSESSIONI='.length);
        }
      }
    }
    return sessionId;
  }
}
