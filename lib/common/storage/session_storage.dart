import 'package:get_storage/get_storage.dart';

class SessionStorage {
  SessionStorage._();

  static const String _webIdKey = 'app_webid';
  static const String _cookieStoreKey = 'app_auth_cookie_store';
  static final GetStorage _box = GetStorage();

  static String? getWebId() {
    final raw = _box.read<String>(_webIdKey);
    final normalized = _normalize(raw);
    if (normalized != null) {
      return normalized;
    }
    return getAuthCookie('WEBID') ??
        getAuthCookie('JSESSIONID') ??
        getAuthCookie('JSESSIONI');
  }

  static void setWebId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _box.write(_webIdKey, trimmed);
    setAuthCookie('WEBID', trimmed);
    setAuthCookie('JSESSIONID', trimmed);
    setAuthCookie('JSESSIONI', trimmed);
  }

  static void clearWebId() {
    _box.remove(_webIdKey);
    removeAuthCookie('WEBID');
    removeAuthCookie('JSESSIONID');
    removeAuthCookie('JSESSIONI');
  }

  static String? getRefreshToken() => getAuthCookie('refresh_token');

  static void setRefreshToken(String value) {
    final normalized = _normalize(value);
    if (normalized == null) {
      return;
    }
    setAuthCookie('refresh_token', normalized);
  }

  static void clearRefreshToken() {
    removeAuthCookie('refresh_token');
  }

  static String? getAuthCookie(String name) {
    final normalizedName = _normalize(name);
    if (normalizedName == null) {
      return null;
    }
    final cookies = getAuthCookies();
    return cookies[normalizedName];
  }

  static Map<String, String> getAuthCookies() {
    final raw = _box.read(_cookieStoreKey);
    if (raw is! Map) {
      return <String, String>{};
    }

    final result = <String, String>{};
    raw.forEach((key, value) {
      final cookieName = _normalize(key?.toString());
      final cookieValue = _normalize(value?.toString());
      if (cookieName == null || cookieValue == null) {
        return;
      }
      result[cookieName] = cookieValue;
    });
    return result;
  }

  static void setAuthCookie(String name, String value) {
    final cookieName = _normalize(name);
    final cookieValue = _normalize(value);
    if (cookieName == null || cookieValue == null) {
      return;
    }

    final cookies = getAuthCookies();
    cookies[cookieName] = cookieValue;
    _box.write(_cookieStoreKey, cookies);
  }

  static void removeAuthCookie(String name) {
    final cookieName = _normalize(name);
    if (cookieName == null) {
      return;
    }

    final cookies = getAuthCookies();
    if (cookies.remove(cookieName) == null) {
      return;
    }
    _box.write(_cookieStoreKey, cookies);
  }

  static void clearAuthCookies() {
    _box.remove(_cookieStoreKey);
    _box.remove(_webIdKey);
  }

  static void mergeAuthCookies(Map<String, String> cookies) {
    if (cookies.isEmpty) {
      return;
    }
    final current = getAuthCookies();
    current.addAll(cookies);
    _box.write(_cookieStoreKey, current);
    final webId =
        current['WEBID'] ?? current['JSESSIONID'] ?? current['JSESSIONI'];
    if (webId != null && webId.isNotEmpty) {
      _box.write(_webIdKey, webId);
    }
  }

  static String? _normalize(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
