import 'package:dio/dio.dart';
import 'package:tronskins_app/common/storage/session_storage.dart';

class CookieInterceptor extends Interceptor {
  static const Set<String> _trackedCookieNames = <String>{
    'WEBID',
    'JSESSIONID',
    'JSESSIONI',
    'refresh_token',
  };

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _syncCookies(response);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _syncCookies(err.response);
    super.onError(err, handler);
  }

  void _syncCookies(Response<dynamic>? response) {
    if (response == null) return;
    final cookies =
        response.headers['set-cookie'] ??
        response.headers['Set-Cookie'] ??
        <String>[];
    if (cookies.isEmpty) return;

    final updates = <String, String>{};
    final removals = <String>{};
    for (final rawCookie in cookies) {
      final parsed = _parseSetCookie(rawCookie);
      if (parsed == null) {
        continue;
      }
      final name = parsed.name;
      if (!_trackedCookieNames.contains(name)) {
        continue;
      }
      if (parsed.isExpired) {
        removals.add(name);
        continue;
      }
      updates[name] = parsed.value;
    }

    if (updates.isNotEmpty) {
      SessionStorage.mergeAuthCookies(updates);
    }
    for (final name in removals) {
      SessionStorage.removeAuthCookie(name);
    }

    final webId =
        SessionStorage.getAuthCookie('WEBID') ??
        SessionStorage.getAuthCookie('JSESSIONID') ??
        SessionStorage.getAuthCookie('JSESSIONI');
    if (webId != null && webId.isNotEmpty) {
      SessionStorage.setWebId(webId);
    }

    final refreshToken = SessionStorage.getAuthCookie('refresh_token');
    if (refreshToken != null && refreshToken.isNotEmpty) {
      SessionStorage.setRefreshToken(refreshToken);
    } else if (removals.contains('refresh_token')) {
      SessionStorage.clearRefreshToken();
    }
  }

  _ParsedCookie? _parseSetCookie(String rawCookie) {
    final parts = rawCookie.split(';');
    if (parts.isEmpty) {
      return null;
    }

    final pair = parts.first;
    final separator = pair.indexOf('=');
    if (separator <= 0) {
      return null;
    }

    final name = pair.substring(0, separator).trim();
    final value = pair.substring(separator + 1).trim();
    if (name.isEmpty) {
      return null;
    }

    var expired = false;
    for (var i = 1; i < parts.length; i++) {
      final attribute = parts[i].trim();
      if (attribute.isEmpty) {
        continue;
      }
      final attrSeparator = attribute.indexOf('=');
      final key = attrSeparator > 0
          ? attribute.substring(0, attrSeparator).trim().toLowerCase()
          : attribute.toLowerCase();
      final attrValue = attrSeparator > 0
          ? attribute.substring(attrSeparator + 1).trim()
          : '';

      if (key == 'max-age') {
        final maxAge = int.tryParse(attrValue);
        if (maxAge != null && maxAge <= 0) {
          expired = true;
        }
      } else if (key == 'expires') {
        final expiresAt = DateTime.tryParse(attrValue);
        if (expiresAt != null &&
            expiresAt.toUtc().isBefore(DateTime.now().toUtc())) {
          expired = true;
        }
      }
    }

    return _ParsedCookie(name: name, value: value, isExpired: expired);
  }
}

class _ParsedCookie {
  const _ParsedCookie({
    required this.name,
    required this.value,
    required this.isExpired,
  });

  final String name;
  final String value;
  final bool isExpired;
}
