// lib/common/http/http_helper.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:tronskins_app/common/storage/server_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/cookie_interceptor.dart';
import 'interceptors/header_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class HttpHelper {
  static HttpHelper? _instance;
  static late Dio _dio;

  static const String defaultBaseUrl = ServerStorage.defaultServer;
  static String _baseUrl = defaultBaseUrl;
  static String get baseUrl => _baseUrl;

  final logger = Logger(
    printer: PrettyPrinter(methodCount: 0, printEmojis: true, colors: true),
  );

  static HttpHelper getInstance() => _instance ??= HttpHelper._internal();

  HttpHelper._internal() {
    _baseUrl = ServerStorage.getServer();
    BaseOptions options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );

    _dio = Dio(options);

    // 安卓/iOS 抓包支持（仅限非 Release）
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      if (!kReleaseMode) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      }
      return client;
    };

    // 拦截器顺序很重要
    _dio.interceptors.add(HeaderInterceptor());
    _dio.interceptors.add(AuthInterceptor()); // 自动加 token
    _dio.interceptors.add(CookieInterceptor()); // WEBID 同步
    _dio.interceptors.add(LoggingInterceptor()); // 美化日志
  }

  /// 必须在 main() 中调用
  static Future<void> init() async {
    await AuthInterceptor.loadTokenFromStorage();
    getInstance();
    setBaseUrl(ServerStorage.getServer());
  }

  // 通用请求
  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (!_canRequestWithoutToken(path)) {
      final blocked = <String, dynamic>{
        'code': 401,
        'message': '登录已过期，请重新登录',
        'datas': null,
      };
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 401,
        data: blocked as T,
      );
    }
    try {
      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(method: method),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool rawAuthorization = false,
    bool skipCookie = false,
  }) {
    final extra = <String, dynamic>{};
    if (rawAuthorization) {
      extra['raw_authorization'] = true;
    }
    if (skipCookie) {
      extra['skip_cookie'] = true;
    }
    final requestOptions = extra.isEmpty ? null : Options(extra: extra);
    return request(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      options: requestOptions,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) => request(
    path,
    method: 'POST',
    data: data,
    queryParameters: queryParameters,
  );

  // 错误统一处理 + 401 清理登录态
  HttpException _handleError(DioException e) {
    String msg = '网络异常';
    final code = e.response?.statusCode;

    if (code == 401) {
      AuthInterceptor.clearToken();
      UserStorage.setUserInfo(null);
      msg = '登录已过期，请重新登录';
    } else if (code == 403) {
      msg = '无权限访问';
    } else if (code != null && code >= 500) {
      msg = '服务器开小差了';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      msg = '连接超时，请检查网络';
    }

    logger.e('HTTP Error [$code]: $msg');
    return HttpException(msg, e);
  }

  void setToken(String token) => AuthInterceptor.setToken(token);
  void clearToken() => AuthInterceptor.clearToken();
  bool get hasToken => AuthInterceptor.hasToken;

  static void setBaseUrl(String url) {
    _baseUrl = url;
    if (_dio.options.baseUrl != url) {
      _dio.options.baseUrl = url;
    }
  }

  bool _canRequestWithoutToken(String path) {
    if (hasToken) {
      return true;
    }
    final normalized = _normalizePath(path);
    if (normalized.startsWith('api/public/')) {
      return true;
    }
    return _authFreePaths.contains(normalized);
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

const Set<String> _authFreePaths = {
  'api/app/auth',
};

class HttpException implements Exception {
  final String message;
  final DioException? dioError;
  HttpException(this.message, [this.dioError]);
  @override
  String toString() => 'HttpException: $message';
}
