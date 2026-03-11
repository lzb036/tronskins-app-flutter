import 'dart:convert';

import 'package:dio/dio.dart';

class SteamAuthClient {
  SteamAuthClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.steampowered.com/',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  final Dio _dio;

  Future<Map<String, dynamic>> getPasswordKey(String accountName) async {
    final response = await _dio.get(
      'IAuthenticationService/GetPasswordRSAPublicKey/v1/',
      queryParameters: {'account_name': accountName},
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> beginAuthSession(
    Map<String, dynamic> data,
  ) async {
    final response = await _postForm(
      'IAuthenticationService/BeginAuthSessionViaCredentials/v1/',
      data,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> updateAuthSessionWithSteamGuardCode(
    Map<String, dynamic> data,
  ) async {
    final response = await _postForm(
      'IAuthenticationService/UpdateAuthSessionWithSteamGuardCode/v1',
      data,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> pollAuthSessionStatus(
    Map<String, dynamic> data,
  ) async {
    final response = await _postForm(
      'IAuthenticationService/PollAuthSessionStatus/v1/',
      data,
    );
    return _asMap(response.data);
  }

  Future<Response<dynamic>> _postForm(String path, Map<String, dynamic> data) {
    return _dio.post(path, data: _toFormBody(data), options: _formOptions());
  }

  String _toFormBody(Map<String, dynamic> data) {
    return data.entries
        .where((entry) => entry.value != null)
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value.toString())}',
        )
        .join('&');
  }

  Options _formOptions() {
    return Options(
      contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
      headers: const {
        'Referer': 'https://steamcommunity.com',
        'Origin': 'https://steamcommunity.com',
      },
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      return _asMap(decoded);
    } catch (_) {
      return <String, dynamic>{};
    }
  }
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}
