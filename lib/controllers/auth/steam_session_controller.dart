import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/api/steam_auth.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class SteamSessionController extends GetxController {
  SteamSessionController({
    ApiSteamServer? steamApi,
    SteamAuthClient? authClient,
    Duration? pollInterval,
    int? maxPollAttempts,
  }) : _steamApi = steamApi ?? ApiSteamServer(),
       _authClient = authClient ?? SteamAuthClient(),
       _pollInterval = pollInterval ?? const Duration(seconds: 5),
       _maxPollAttempts = maxPollAttempts ?? 30;

  final ApiSteamServer _steamApi;
  final SteamAuthClient _authClient;
  final Duration _pollInterval;
  final int _maxPollAttempts;

  final accountController = TextEditingController();
  final passwordController = TextEditingController();
  final codeController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isCodeSubmitting = false.obs;
  final RxBool isWaitingForVerificationResult = false.obs;
  final RxBool isAwaitingVerification = false.obs;
  final RxBool isCodeDialogVisible = false.obs;
  final RxBool verificationSucceeded = false.obs;
  final RxString errorMessage = ''.obs;

  String? _clientId;
  String? _requestId;
  String? _steamId;
  Future<bool>? _pollingFuture;
  Future<bool>? _tokenSaveFuture;
  int _sessionGeneration = 0;

  Future<void> startLogin() async {
    if (isLoading.value || isCodeSubmitting.value) {
      return;
    }

    if (isAwaitingVerification.value) {
      isCodeDialogVisible.value = true;
      return;
    }

    final account = accountController.text.trim();
    final password = passwordController.text;
    if (account.isEmpty || password.isEmpty) {
      errorMessage.value = account.isEmpty
          ? 'app.steam.session.message.username_error'
          : 'app.user.login.message.password_error';
      return;
    }

    final generation = _replaceSessionState();
    verificationSucceeded.value = false;
    errorMessage.value = '';
    isLoading.value = true;

    try {
      final keyRes = await _authClient.getPasswordKey(account);
      final keyData = _responseData(keyRes);
      final publicKeyMod = _readString(
        _firstNonNull([keyData['publickey_mod'], keyRes['publickey_mod']]),
      );
      final publicKeyExp = _readString(
        _firstNonNull([keyData['publickey_exp'], keyRes['publickey_exp']]),
      );
      final timestamp = _readString(
        _firstNonNull([keyData['timestamp'], keyRes['timestamp']]),
      );

      if (publicKeyMod.isEmpty || publicKeyExp.isEmpty || timestamp.isEmpty) {
        errorMessage.value = 'app.user.login.message.error';
        return;
      }

      final encryptRes = await _steamApi.decryptSteamPassword(
        account: account,
        password: password,
        publicKeyMod: publicKeyMod,
        publicKeyExp: publicKeyExp,
      );
      final encryptedPassword = _readString(encryptRes.datas);
      if (!encryptRes.success || encryptedPassword.isEmpty) {
        errorMessage.value = 'app.user.login.message.error';
        return;
      }

      final sessionRes = await _authClient.beginAuthSession({
        'persistence': '1',
        'encrypted_password': encryptedPassword,
        'account_name': account,
        'encryption_timestamp': timestamp,
      });
      final sessionData = _responseData(sessionRes);

      _clientId = _readString(
        _firstNonNull([sessionData['client_id'], sessionRes['client_id']]),
      );
      _requestId = _readString(
        _firstNonNull([sessionData['request_id'], sessionRes['request_id']]),
      );
      _steamId = _readString(
        _firstNonNull([sessionData['steamid'], sessionRes['steamid']]),
      );

      if (_clientId!.isEmpty || _requestId!.isEmpty || _steamId!.isEmpty) {
        errorMessage.value = 'app.user.login.message.error';
        return;
      }

      isAwaitingVerification.value = true;
      isCodeDialogVisible.value = true;
      _startPollingIfNeeded(generation);
    } catch (_) {
      errorMessage.value = 'app.user.login.message.error';
    } finally {
      isLoading.value = false;
    }
  }

  void showCodeDialog() {
    if (!isAwaitingVerification.value) {
      return;
    }
    isCodeDialogVisible.value = true;
  }

  void hideCodeDialog() {
    isCodeDialogVisible.value = false;
  }

  Future<void> submitCode() async {
    if (isCodeSubmitting.value ||
        isLoading.value ||
        isWaitingForVerificationResult.value) {
      return;
    }

    final generation = _sessionGeneration;
    final clientId = _clientId;
    final steamId = _steamId;
    if (!isAwaitingVerification.value ||
        clientId == null ||
        steamId == null ||
        clientId.isEmpty ||
        steamId.isEmpty) {
      errorMessage.value = 'app.user.login.message.error';
      return;
    }

    final code = codeController.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{5}$').hasMatch(code)) {
      errorMessage.value = code.isEmpty
          ? 'app.user.login.message.code_error'
          : 'app.user.login.message.code_length_error';
      return;
    }

    isCodeSubmitting.value = true;
    isWaitingForVerificationResult.value = false;
    errorMessage.value = '';

    try {
      final authRes = await _authClient.updateAuthSessionWithSteamGuardCode({
        'client_id': clientId,
        'steamid': steamId,
        'code_type': '3',
        'code': code,
      });
      if (generation != _sessionGeneration) {
        return;
      }

      final authData = _responseData(authRes);
      final refreshToken = _readString(
        _firstNonNull([authData['refresh_token'], authRes['refresh_token']]),
      );
      final result = _firstNonNull([authData['eresult'], authRes['eresult']]);

      if (refreshToken.isNotEmpty) {
        await _consumeRefreshToken(refreshToken, generation: generation);
        return;
      }

      if (_isSteamResultError(result)) {
        codeController.clear();
        errorMessage.value = 'app.user.login.message.error';
        return;
      }

      // Old project behavior keeps polling running after code submission.
      isWaitingForVerificationResult.value = true;
    } catch (_) {
      isWaitingForVerificationResult.value = false;
      codeController.clear();
      errorMessage.value = 'app.user.login.message.error';
    } finally {
      isCodeSubmitting.value = false;
    }
  }

  Future<bool> _startPollingIfNeeded(int generation) {
    final existing = _pollingFuture;
    if (existing != null) {
      return existing;
    }
    final future = _pollForToken(generation);
    _pollingFuture = future;
    future.whenComplete(() {
      if (identical(_pollingFuture, future)) {
        _pollingFuture = null;
      }
    });
    return future;
  }

  Future<bool> _pollForToken(int generation) async {
    final clientId = _clientId;
    final requestId = _requestId;
    if (clientId == null ||
        requestId == null ||
        clientId.isEmpty ||
        requestId.isEmpty) {
      _failVerification(
        clearCredentials: false,
        message: 'app.user.login.message.error',
      );
      return false;
    }

    for (var attempt = 0; attempt < _maxPollAttempts; attempt += 1) {
      if (generation != _sessionGeneration) {
        return false;
      }

      try {
        final pollRes = await _authClient.pollAuthSessionStatus({
          'client_id': clientId,
          'request_id': requestId,
        });
        if (generation != _sessionGeneration) {
          return false;
        }

        final pollData = _responseData(pollRes);
        final refreshToken = _readString(
          _firstNonNull([pollData['refresh_token'], pollRes['refresh_token']]),
        );
        final result = _firstNonNull([pollData['eresult'], pollRes['eresult']]);

        if (refreshToken.isNotEmpty) {
          return await _consumeRefreshToken(
            refreshToken,
            generation: generation,
          );
        }

        if (_isSteamResultError(result)) {
          _failVerification(
            clearCredentials: false,
            message: 'app.user.login.message.error',
          );
          return false;
        }
      } catch (_) {
        _failVerification(
          clearCredentials: false,
          message: 'app.user.login.message.error',
        );
        return false;
      }

      await Future<void>.delayed(_pollInterval);
    }

    if (generation != _sessionGeneration) {
      return false;
    }

    _failVerification(
      clearCredentials: false,
      message: 'app.user.login.message.error',
    );
    return false;
  }

  Future<bool> _consumeRefreshToken(
    String refreshToken, {
    required int generation,
  }) {
    final existing = _tokenSaveFuture;
    if (existing != null) {
      return existing;
    }

    final future = _applyRefreshToken(refreshToken, generation: generation);
    _tokenSaveFuture = future;
    future.whenComplete(() {
      if (identical(_tokenSaveFuture, future)) {
        _tokenSaveFuture = null;
      }
    });
    return future;
  }

  Future<bool> _applyRefreshToken(
    String refreshToken, {
    required int generation,
  }) async {
    if (generation != _sessionGeneration) {
      return false;
    }

    final steamId = _steamId;
    if (steamId == null || steamId.isEmpty) {
      _failVerification(
        clearCredentials: false,
        message: 'app.user.login.message.error',
      );
      return false;
    }

    final res = await _steamApi.steamTokenFresh(
      steamId: steamId,
      freshToken: refreshToken,
    );
    if (generation != _sessionGeneration) {
      return false;
    }

    if (!res.success) {
      _failVerification(
        clearCredentials: true,
        message: _resolveTokenFreshFailureMessage(res),
      );
      return false;
    }

    _replaceSessionState(clearCredentials: true);
    errorMessage.value = '';
    verificationSucceeded.value = true;
    return true;
  }

  int _replaceSessionState({bool clearCredentials = false}) {
    _sessionGeneration += 1;
    _clientId = null;
    _requestId = null;
    _steamId = null;
    _pollingFuture = null;
    _tokenSaveFuture = null;
    isAwaitingVerification.value = false;
    isWaitingForVerificationResult.value = false;
    isCodeDialogVisible.value = false;
    isCodeSubmitting.value = false;
    codeController.clear();
    if (clearCredentials) {
      accountController.clear();
      passwordController.clear();
    }
    return _sessionGeneration;
  }

  void _failVerification({
    required bool clearCredentials,
    required String message,
  }) {
    _replaceSessionState(clearCredentials: clearCredentials);
    verificationSucceeded.value = false;
    errorMessage.value = message;
  }

  String _resolveTokenFreshFailureMessage(BaseHttpResponse<dynamic> res) {
    final datasText = _readString(res.datas);
    final messageText = _readString(res.message);
    final raw = datasText.isNotEmpty ? datasText : messageText;
    if (raw.toLowerCase() == 'unbind steam') {
      return 'app.steam.message.unbind';
    }
    if (raw.isNotEmpty) {
      return raw;
    }
    return 'app.user.login.message.error';
  }

  Map<String, dynamic> _responseData(Map<String, dynamic> payload) {
    final response = payload['response'];
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return const <String, dynamic>{};
  }

  dynamic _firstNonNull(Iterable<dynamic> values) {
    for (final value in values) {
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  String _readString(dynamic value) {
    final text = value?.toString() ?? '';
    return text.trim();
  }

  bool _isSteamResultError(dynamic result) {
    if (result == null) {
      return false;
    }
    final value = result is int ? result : int.tryParse(result.toString());
    if (value == null) {
      return false;
    }
    return value != 0 && value != 1;
  }

  @override
  void onClose() {
    _replaceSessionState(clearCredentials: false);
    accountController.dispose();
    passwordController.dispose();
    codeController.dispose();
    super.onClose();
  }
}
