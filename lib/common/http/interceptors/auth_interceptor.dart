import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tronskins_app/common/security/secure_storage.dart';
import 'package:tronskins_app/common/storage/session_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';

class AuthInterceptor extends Interceptor {
  static const String _tokenKey = 'auth_token';
  static const String _accessTokenExpireTimeKey = 'es_access_token_expire_time';
  static const String _refreshTokenExpireTimeKey =
      'es_refresh_token_expire_time';
  static const String _skipTokenKey = 'skip_token';
  static const String _skipAuthRefreshKey = 'skip_auth_refresh';
  static const String _retryAfterRefreshKey = '__retry_after_refresh';
  static const String _rawAuthorizationKey = 'raw_authorization';
  static const String _refreshEndpoint = 'api/app/auth/refresh';
  static const Duration _tokenExpireAdvance = Duration(seconds: 30);
  static const Set<dynamic> _tokenInvalidCodes = <dynamic>{
    401,
    1001,
    '401',
    '1001',
  };

  static String? _token;
  static int? _accessTokenExpireTime;
  static int? _refreshTokenExpireTime;
  static Dio? _dio;
  static Future<_RefreshResult>? _refreshFuture;

  static Future<void> loadTokenFromStorage() async {
    _token = await SecureStorage.getItem(_tokenKey);
    final box = GetStorage();
    _accessTokenExpireTime = _toInt(box.read(_accessTokenExpireTimeKey));
    _refreshTokenExpireTime = _toInt(box.read(_refreshTokenExpireTimeKey));
  }

  static void bindDio(Dio dio) {
    _dio = dio;
  }

  static Future<void> setToken(String token) async {
    await setAccessToken(accessToken: token);
  }

  static Future<void> setAccessToken({
    required String accessToken,
    int? accessTokenExpireTime,
    int? refreshTokenExpireTime,
    String? header,
  }) async {
    final normalizedToken = accessToken.trim();
    if (normalizedToken.isEmpty) {
      await clearToken();
      return;
    }

    _token = normalizedToken;
    await SecureStorage.setItem(_tokenKey, normalizedToken);

    final box = GetStorage();
    final normalizedAccessExpire =
        accessTokenExpireTime ?? _parseJwtExpireTime(normalizedToken);
    _accessTokenExpireTime = normalizedAccessExpire;
    if (normalizedAccessExpire == null) {
      box.remove(_accessTokenExpireTimeKey);
    } else {
      box.write(_accessTokenExpireTimeKey, normalizedAccessExpire);
    }

    if (refreshTokenExpireTime != null) {
      _refreshTokenExpireTime = refreshTokenExpireTime;
      box.write(_refreshTokenExpireTimeKey, refreshTokenExpireTime);
    }
  }

  static Future<void> clearToken({bool clearRefreshTokenCookie = true}) async {
    _token = null;
    _accessTokenExpireTime = null;
    _refreshTokenExpireTime = null;
    _refreshFuture = null;

    await SecureStorage.removeItem(_tokenKey);
    final box = GetStorage();
    box.remove(_accessTokenExpireTimeKey);
    box.remove(_refreshTokenExpireTimeKey);

    if (clearRefreshTokenCookie) {
      SessionStorage.clearRefreshToken();
    }
  }

  static bool get hasToken => _token != null && _token!.isNotEmpty;
  static String? get token => _token;
  static int? get accessTokenExpireTime => _accessTokenExpireTime;
  static int? get refreshTokenExpireTime => _refreshTokenExpireTime;

  /// Debug helper: override local access token expire time.
  static Future<void> setAccessTokenExpireTimeForDebug(int? expireTime) async {
    _accessTokenExpireTime = expireTime;
    final box = GetStorage();
    if (expireTime == null) {
      box.remove(_accessTokenExpireTimeKey);
      return;
    }
    box.write(_accessTokenExpireTimeKey, expireTime);
  }

  static bool get isAccessTokenExpired {
    if (!hasToken) return true;
    final expireTime = _accessTokenExpireTime;
    if (expireTime == null) return false;
    final threshold = DateTime.now()
        .add(_tokenExpireAdvance)
        .millisecondsSinceEpoch;
    return threshold >= expireTime;
  }

  static Future<bool> ensureAccessTokenAvailable({
    required bool forceRefresh,
  }) async {
    final availability = await _ensureAccessTokenAvailability(
      forceRefresh: forceRefresh,
    );
    return availability.available;
  }

  static Future<_TokenAvailability> _ensureAccessTokenAvailability({
    required bool forceRefresh,
  }) async {
    if (!hasToken) {
      return const _TokenAvailability(available: false, authInvalid: true);
    }
    if (!forceRefresh && !isAccessTokenExpired) {
      return const _TokenAvailability(available: true, authInvalid: false);
    }

    _refreshFuture ??= _refreshAccessToken().whenComplete(() {
      _refreshFuture = null;
    });
    final refreshResult = await _refreshFuture!;
    switch (refreshResult) {
      case _RefreshResult.success:
        return const _TokenAvailability(available: true, authInvalid: false);
      case _RefreshResult.authInvalid:
        return const _TokenAvailability(available: false, authInvalid: true);
      case _RefreshResult.transientFailure:
        return const _TokenAvailability(available: false, authInvalid: false);
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipToken = _shouldSkipTokenAttach(options);
    if (!skipToken && hasToken) {
      _applyAuthorizationHeader(options);
    }

    if (!_shouldAutoRefresh(options)) {
      handler.next(options);
      return;
    }

    final availability = await _ensureAccessTokenAvailability(
      forceRefresh: false,
    );
    if (!availability.available && availability.authInvalid) {
      await _clearAuthState();
      handler.reject(_buildAuthExpiredException(options), true);
      return;
    }

    if (!skipToken && hasToken) {
      _applyAuthorizationHeader(options);
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (!_isTokenInvalidResponse(response)) {
      handler.next(response);
      return;
    }

    final requestOptions = response.requestOptions;
    if (!_canHandleAuthFailure(requestOptions)) {
      handler.next(response);
      return;
    }

    if (requestOptions.extra[_retryAfterRefreshKey] == true) {
      await _clearAuthState();
      handler.next(response);
      return;
    }

    final availability = await _ensureAccessTokenAvailability(
      forceRefresh: true,
    );
    if (!availability.available) {
      if (availability.authInvalid) {
        await _clearAuthState();
      }
      handler.next(response);
      return;
    }

    try {
      final retried = await _retryRequest(requestOptions);
      handler.resolve(retried);
    } on DioException catch (error) {
      handler.reject(error);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isTokenInvalidError(err)) {
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;
    if (!_canHandleAuthFailure(requestOptions)) {
      handler.next(err);
      return;
    }

    if (requestOptions.extra[_retryAfterRefreshKey] == true) {
      await _clearAuthState();
      handler.next(err);
      return;
    }

    final availability = await _ensureAccessTokenAvailability(
      forceRefresh: true,
    );
    if (!availability.available) {
      if (availability.authInvalid) {
        await _clearAuthState();
      }
      handler.next(err);
      return;
    }

    try {
      final retried = await _retryRequest(requestOptions);
      handler.resolve(retried);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  static bool _shouldAutoRefresh(RequestOptions options) {
    if (options.extra[_skipAuthRefreshKey] == true) {
      return false;
    }
    if (_isRefreshRequest(options.path)) {
      return false;
    }
    if (options.extra[_skipTokenKey] == true) {
      return false;
    }
    if (_isPublicRequest(options.path)) {
      return false;
    }
    if (!hasToken) {
      return false;
    }
    return true;
  }

  static bool _shouldSkipTokenAttach(RequestOptions options) {
    if (options.extra[_skipTokenKey] == true) {
      return true;
    }
    if (_isRefreshRequest(options.path)) {
      return true;
    }
    return false;
  }

  static bool _canHandleAuthFailure(RequestOptions options) {
    if (options.extra[_skipAuthRefreshKey] == true) {
      return false;
    }
    if (options.extra[_skipTokenKey] == true) {
      return false;
    }
    if (_isRefreshRequest(options.path)) {
      return false;
    }
    if (_isPublicRequest(options.path)) {
      return false;
    }
    if (!hasToken) {
      return false;
    }
    return true;
  }

  static Future<_RefreshResult> _refreshAccessToken() async {
    final dio = _dio;
    if (dio == null) {
      return _RefreshResult.transientFailure;
    }

    try {
      final response = await dio.post<dynamic>(
        '/$_refreshEndpoint',
        data: const <String, dynamic>{},
        options: Options(
          extra: <String, dynamic>{
            _skipTokenKey: true,
            _skipAuthRefreshKey: true,
          },
        ),
      );

      final statusCode = response.statusCode ?? 200;
      if (statusCode < 200 || statusCode >= 300) {
        if (_isTokenInvalidResponse(response)) {
          return _RefreshResult.authInvalid;
        }
        return _RefreshResult.transientFailure;
      }

      if (!_isRefreshBusinessSuccess(response.data)) {
        final businessCode = _extractBusinessCode(response.data);
        if (_tokenInvalidCodes.contains(businessCode)) {
          return _RefreshResult.authInvalid;
        }
        return _RefreshResult.transientFailure;
      }

      final tokenPayload = _extractTokenPayload(response.data);
      if (tokenPayload == null) {
        return _RefreshResult.transientFailure;
      }

      await setAccessToken(
        accessToken: tokenPayload.accessToken,
        accessTokenExpireTime: tokenPayload.accessTokenExpireTime,
        refreshTokenExpireTime: tokenPayload.refreshTokenExpireTime,
        header: tokenPayload.header,
      );
      return _RefreshResult.success;
    } on DioException catch (error) {
      if (_isTokenInvalidError(error)) {
        return _RefreshResult.authInvalid;
      }
      return _RefreshResult.transientFailure;
    } catch (_) {
      return _RefreshResult.transientFailure;
    }
  }

  static Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
  ) async {
    final dio = _dio;
    if (dio == null) {
      throw DioException(
        requestOptions: requestOptions,
        error: 'Dio instance is not bound to AuthInterceptor',
      );
    }

    final headers = Map<String, dynamic>.from(requestOptions.headers);
    if (hasToken) {
      final useRawAuthorization =
          requestOptions.extra[_rawAuthorizationKey] == true;
      headers['Authorization'] = useRawAuthorization
          ? _token
          : 'Bearer $_token';
    }

    final extra = Map<String, dynamic>.from(requestOptions.extra);
    extra[_retryAfterRefreshKey] = true;

    final options = Options(
      method: requestOptions.method,
      sendTimeout: requestOptions.sendTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
      headers: headers,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      extra: extra,
      followRedirects: requestOptions.followRedirects,
      listFormat: requestOptions.listFormat,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      validateStatus: requestOptions.validateStatus,
      requestEncoder: requestOptions.requestEncoder,
      responseDecoder: requestOptions.responseDecoder,
    );

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
      cancelToken: requestOptions.cancelToken,
      onSendProgress: requestOptions.onSendProgress,
      onReceiveProgress: requestOptions.onReceiveProgress,
    );
  }

  static void _applyAuthorizationHeader(RequestOptions options) {
    final token = _token;
    if (token == null || token.isEmpty) {
      return;
    }

    final useRawAuthorization = options.extra[_rawAuthorizationKey] == true;
    if (useRawAuthorization) {
      options.headers['Authorization'] = token;
      return;
    }
    options.headers['Authorization'] = 'Bearer $token';
  }

  static bool _isTokenInvalidResponse(Response<dynamic> response) {
    final statusCode = response.statusCode;
    if (statusCode == 401) {
      return true;
    }
    final code = _extractBusinessCode(response.data);
    return _tokenInvalidCodes.contains(code);
  }

  static bool _isTokenInvalidError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    if (statusCode == 401) {
      return true;
    }
    final code = _extractBusinessCode(response?.data);
    return _tokenInvalidCodes.contains(code);
  }

  static dynamic _extractBusinessCode(dynamic data) {
    if (data is! Map) {
      return null;
    }
    return data['code'] ?? data['statusCode'];
  }

  static bool _isRefreshBusinessSuccess(dynamic data) {
    if (data is! Map) {
      return true;
    }
    final code = data['code'];
    if (code == null) {
      return true;
    }
    return code == 0 || code == 200 || code == '0' || code == '200';
  }

  static _TokenPayload? _extractTokenPayload(dynamic responseData) {
    if (responseData is! Map) {
      return null;
    }

    final dynamic datas = responseData['datas'];
    final dynamic dataField = responseData['data'];
    final Map<dynamic, dynamic> data = datas is Map
        ? datas
        : (dataField is Map ? dataField : responseData);

    final accessToken =
        _readString(data, 'accessToken') ?? _readString(data, 'token');
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final accessTokenExpireTime = _toInt(data['accessTokenExpireTime']);
    final refreshTokenExpireTime =
        _toInt(data['refreshTokenExpireTime']) ??
        _toInt(data['refreshExpireTime']);
    final header = _readString(data, 'header');

    return _TokenPayload(
      accessToken: accessToken,
      accessTokenExpireTime: accessTokenExpireTime,
      refreshTokenExpireTime: refreshTokenExpireTime,
      header: header,
    );
  }

  static bool _isRefreshRequest(String path) {
    final normalized = _normalizePath(path);
    return normalized.contains(_refreshEndpoint);
  }

  static bool _isPublicRequest(String path) {
    final normalized = _normalizePath(path);
    return normalized.startsWith('api/public/');
  }

  static String _normalizePath(String? path) {
    if (path == null || path.trim().isEmpty) {
      return '';
    }
    var normalized = path.trim();
    if (normalized.startsWith('http')) {
      normalized = Uri.parse(normalized).path;
    }
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }

  static DioException _buildAuthExpiredException(RequestOptions options) {
    final payload = <String, dynamic>{
      'code': 401,
      'message': '登录已过期，请重新登录',
      'datas': null,
    };
    return DioException(
      requestOptions: options,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 401,
        data: payload,
      ),
      error: '登录已过期，请重新登录',
      type: DioExceptionType.badResponse,
    );
  }

  static int? _parseJwtExpireTime(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return null;
      }
      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final data = jsonDecode(decoded);
      if (data is! Map) {
        return null;
      }
      final exp = _toInt(data['exp']);
      if (exp == null) {
        return null;
      }
      return exp * 1000;
    } catch (_) {
      return null;
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  static String? _readString(Map<dynamic, dynamic> data, String key) {
    final value = data[key];
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  static Future<void> _clearAuthState() async {
    await clearToken();
    UserStorage.setUserInfo(null);
  }
}

class _TokenPayload {
  const _TokenPayload({
    required this.accessToken,
    this.accessTokenExpireTime,
    this.refreshTokenExpireTime,
    this.header,
  });

  final String accessToken;
  final int? accessTokenExpireTime;
  final int? refreshTokenExpireTime;
  final String? header;
}

enum _RefreshResult { success, authInvalid, transientFailure }

class _TokenAvailability {
  const _TokenAvailability({
    required this.available,
    required this.authInvalid,
  });

  final bool available;
  final bool authInvalid;
}
