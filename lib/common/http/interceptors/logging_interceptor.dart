// lib/common/http/interceptors/logging_interceptor.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class LoggingInterceptor extends Interceptor {
  final logger = Logger(
    printer: PrettyPrinter(methodCount: 0, printEmojis: true, colors: true),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.i('┌─ REQUEST ─────────────────────────────────────');
    logger.i('│ ${options.method} ${options.uri}');
    if (options.headers.isNotEmpty) {
      logger.i(_formatBlock('Headers', options.headers));
    }
    if (options.data != null) {
      logger.i(_formatBlock('Body', options.data));
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.i('├─ RESPONSE ────────────────────────────────────');
    logger.i('│ ${response.statusCode} ${response.requestOptions.uri}');
    logger.i(_formatBlock('Data', response.data));
    logger.i('└────────────────────────────────────────────────');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e('└─ ERROR ───────────────────────────────────────');
    logger.e('│ ${err.response?.statusCode} ${err.requestOptions.uri}');
    logger.e('│ ${err.message}');
    logger.e('│ Type: ${err.type}');
    if (err.response != null) {
      logger.e(_formatBlock('Response', err.response?.data));
      logger.e(_formatBlock('Headers', err.response?.headers.map));
    }
    super.onError(err, handler);
  }

  String _formatBlock(String title, dynamic data) {
    final pretty = _prettyJson(data);
    final lines = pretty.split('\n');
    final buffer = StringBuffer('│ $title:');
    for (final line in lines) {
      buffer.write('\n│   $line');
    }
    return buffer.toString();
  }

  String _prettyJson(dynamic data) {
    if (data == null) {
      return 'null';
    }
    try {
      if (data is String) {
        final trimmed = data.trim();
        if (trimmed.isEmpty) {
          return data;
        }
        final decoded = json.decode(trimmed);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      if (data is FormData) {
        final map = <String, dynamic>{};
        for (final field in data.fields) {
          final existing = map[field.key];
          if (existing == null) {
            map[field.key] = field.value;
          } else if (existing is List) {
            existing.add(field.value);
          } else {
            map[field.key] = [existing, field.value];
          }
        }
        if (data.files.isNotEmpty) {
          map['__files'] = data.files
              .map((file) => {
                    'field': file.key,
                    'filename': file.value.filename,
                    'contentType': file.value.contentType?.toString(),
                    'length': file.value.length,
                  })
              .toList();
        }
        return const JsonEncoder.withIndent('  ').convert(map);
      }
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }
}
