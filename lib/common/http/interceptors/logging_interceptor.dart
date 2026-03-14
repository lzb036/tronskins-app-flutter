import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestTag = _requestTag(response.requestOptions);
    final successful = _isSuccessfulResponse(response);

    _printLog('[HTTP][${successful ? 'SUCCESS' : 'FAILED'}] $requestTag');

    if (!successful) {
      _printLog('[HTTP][FAILED][RESULT] ${_stringify(response.data)}');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestTag = _requestTag(err.requestOptions);
    final result =
        err.response?.data ??
        <String, dynamic>{
          'type': err.type.name,
          'message': err.message,
          'error': err.error?.toString(),
        };

    _printLog('[HTTP][FAILED] $requestTag');
    _printLog('[HTTP][FAILED][RESULT] ${_stringify(result)}');

    handler.next(err);
  }

  bool _isSuccessfulResponse(Response response) {
    final businessCode = _extractBusinessCode(response.data);
    if (businessCode != null) {
      return businessCode == 0 || businessCode == 200;
    }

    final statusCode = response.statusCode ?? 0;
    return statusCode >= 200 && statusCode < 300;
  }

  int? _extractBusinessCode(dynamic data) {
    if (data is Map<String, dynamic>) {
      final code = data['code'];
      if (code is int) {
        return code;
      }
      if (code is num) {
        return code.toInt();
      }
      if (code is String) {
        return int.tryParse(code.trim());
      }
    }
    return null;
  }

  String _requestTag(RequestOptions options) {
    return '${options.method.toUpperCase()} ${options.uri}';
  }

  String _stringify(dynamic data) {
    if (data == null) {
      return 'null';
    }
    if (data is String) {
      return data;
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  void _printLog(String message) {
    const chunkSize = 800;
    if (message.length <= chunkSize) {
      debugPrint(message);
      return;
    }

    for (var start = 0; start < message.length; start += chunkSize) {
      final end = (start + chunkSize < message.length)
          ? start + chunkSize
          : message.length;
      debugPrint(message.substring(start, end));
    }
  }
}
