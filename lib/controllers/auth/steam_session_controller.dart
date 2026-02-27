import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/api/steam_auth.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/common/storage/steam_storage.dart';

class SteamSessionController extends GetxController {
  SteamSessionController({
    ApiSteamServer? steamApi,
    SteamAuthClient? authClient,
  }) : _steamApi = steamApi ?? ApiSteamServer(),
       _authClient = authClient ?? SteamAuthClient();

  final ApiSteamServer _steamApi;
  final SteamAuthClient _authClient;

  final accountController = TextEditingController();
  final passwordController = TextEditingController();
  final codeController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isAwaitingCode = false.obs;
  final RxString errorMessage = ''.obs;

  String? _clientId;
  String? _requestId;
  String? _steamId;
  Future<bool>? _pollingFuture;
  int _pollGeneration = 0;

  @override
  void onInit() {
    super.onInit();
    _loadStoredCredentials();
  }

  Future<void> _loadStoredCredentials() async {
    final storedAccount = SteamStorage.getAccount();
    final storedPassword = await SteamStorage.getPassword();
    if (storedAccount != null && storedAccount.isNotEmpty) {
      accountController.text = storedAccount;
    }
    if (storedPassword != null && storedPassword.isNotEmpty) {
      passwordController.text = storedPassword;
    }
  }

  Future<void> startLogin() async {
    if (isLoading.value) {
      return;
    }
    final account = accountController.text.trim();
    final password = passwordController.text;
    _logEvent('startLogin.begin', {
      'accountLen': account.length,
      'passwordLen': password.length,
    });
    if (account.isEmpty || password.isEmpty) {
      _logEvent('startLogin.invalidInput', {
        'accountEmpty': account.isEmpty,
        'passwordEmpty': password.isEmpty,
      });
      errorMessage.value = account.isEmpty
          ? 'app.steam.session.message.username_error'
          : 'app.user.login.message.password_error';
      return;
    }

    _resetPollingContext();
    isLoading.value = true;
    errorMessage.value = '';
    isAwaitingCode.value = false;
    try {
      final keyRes = await _authClient.getPasswordKey(account);
      final keyData = keyRes['response'] is Map
          ? Map<String, dynamic>.from(keyRes['response'] as Map)
          : <String, dynamic>{};
      final publicKeyMod = keyData['publickey_mod']?.toString() ?? '';
      final publicKeyExp = keyData['publickey_exp']?.toString() ?? '';
      final timestamp = keyData['timestamp']?.toString() ?? '';
      _logEvent('startLogin.rsaKey', {
        'responseKeys': _mapKeys(keyData),
        'hasPublicKeyMod': publicKeyMod.isNotEmpty,
        'hasPublicKeyExp': publicKeyExp.isNotEmpty,
        'hasTimestamp': timestamp.isNotEmpty,
      });

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
      _logEvent('startLogin.decryptPassword', {
        'success': encryptRes.success,
        'hasEncryptedPassword':
            (encryptRes.datas != null && encryptRes.datas!.isNotEmpty),
      });
      if (!encryptRes.success || encryptRes.datas == null) {
        errorMessage.value = 'app.user.login.message.error';
        return;
      }

      final sessionRes = await _authClient.beginAuthSession({
        'persistence': '1',
        'encrypted_password': encryptRes.datas!,
        'account_name': account,
        'encryption_timestamp': timestamp,
      });
      final sessionData = sessionRes['response'] is Map
          ? Map<String, dynamic>.from(sessionRes['response'] as Map)
          : <String, dynamic>{};

      _clientId = sessionData['client_id']?.toString();
      _requestId = sessionData['request_id']?.toString();
      _steamId = sessionData['steamid']?.toString();
      _logEvent('startLogin.beginAuthSession', {
        'responseKeys': _mapKeys(sessionData),
        'hasClientId': _clientId != null && _clientId!.isNotEmpty,
        'hasRequestId': _requestId != null && _requestId!.isNotEmpty,
        'hasSteamId': _steamId != null && _steamId!.isNotEmpty,
        'clientId': _maskId(_clientId),
        'requestId': _maskId(_requestId),
        'steamId': _maskId(_steamId),
      });

      if (_clientId == null || _requestId == null || _steamId == null) {
        errorMessage.value = 'app.user.login.message.error';
        return;
      }

      isAwaitingCode.value = true;
      unawaited(_startPollingIfNeeded());
    } catch (e) {
      _logEvent('startLogin.error', {
        'errorType': e.runtimeType.toString(),
        'error': e.toString(),
      });
      errorMessage.value = 'app.user.login.message.error';
    } finally {
      isLoading.value = false;
      _logEvent('startLogin.end', {
        'isAwaitingCode': isAwaitingCode.value,
        'hasError': errorMessage.value.isNotEmpty,
      });
    }
  }

  Future<bool> submitCodeAndRefresh() async {
    if (_clientId == null || _steamId == null || _requestId == null) {
      errorMessage.value = 'app.user.login.message.error';
      return false;
    }
    final code = codeController.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{5}$').hasMatch(code)) {
      _logEvent('submitCode.invalidInput', {
        'codeLen': code.length,
      });
      errorMessage.value = 'app.user.login.message.error';
      return false;
    }
    _logEvent('submitCode.begin', {
      'codeLen': code.length,
      'clientId': _maskId(_clientId),
      'requestId': _maskId(_requestId),
      'steamId': _maskId(_steamId),
    });

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final authRes = await _authClient.updateAuthSessionWithSteamGuardCode({
        'client_id': _clientId!,
        'steamid': _steamId!,
        'code_type': '3',
        'code': code,
      });
      final authData = authRes['response'] is Map
          ? Map<String, dynamic>.from(authRes['response'] as Map)
          : <String, dynamic>{};
      final result = authData['eresult'];
      final refreshToken = authData['refresh_token']?.toString();
      final agreementSessionUrl =
          authData['agreement_session_url']?.toString() ?? '';
      _logEvent('submitCode.updateAuthSession', {
        'topLevelKeys': _mapKeys(authRes),
        'responseKeys': _mapKeys(authData),
        'eresult': result,
        'hasRefreshToken': refreshToken != null && refreshToken.isNotEmpty,
        'refreshTokenLen': refreshToken?.length ?? 0,
        'hasAgreementSessionUrl': agreementSessionUrl.isNotEmpty,
      });

      if (_isSteamResultError(result)) {
        _logEvent('submitCode.updateAuthSession.reject', {
          'eresult': result,
        });
        errorMessage.value = 'app.user.login.message.error';
        return false;
      }

      if (refreshToken != null && refreshToken.isNotEmpty) {
        _logEvent('submitCode.useDirectRefreshToken', {
          'refreshTokenLen': refreshToken.length,
        });
        return await _applyRefreshToken(refreshToken);
      }

      if (agreementSessionUrl.isNotEmpty) {
        _logEvent('submitCode.requireAgreementSession', {
          'agreementSessionUrlLen': agreementSessionUrl.length,
        });
        errorMessage.value = 'app.user.login.message.error';
        return false;
      }

      _logEvent('submitCode.startPolling', {
        'reason': 'await_existing_polling',
      });
      final polling = _pollingFuture;
      if (polling == null) {
        _logEvent('submitCode.pollMissing', {
          'reason': 'polling_not_started',
        });
        errorMessage.value = 'app.user.login.message.error';
        return false;
      }
      return await polling;
    } catch (e) {
      _logEvent('submitCode.error', {
        'errorType': e.runtimeType.toString(),
        'error': e.toString(),
      });
      errorMessage.value = 'app.user.login.message.error';
      return false;
    } finally {
      isLoading.value = false;
      _logEvent('submitCode.end', {
        'isAwaitingCode': isAwaitingCode.value,
        'hasError': errorMessage.value.isNotEmpty,
      });
    }
  }

  Future<bool> _startPollingIfNeeded() {
    final existing = _pollingFuture;
    if (existing != null) {
      return existing;
    }
    final generation = _pollGeneration;
    final future = _pollForToken(generation);
    _pollingFuture = future;
    future.whenComplete(() {
      if (identical(_pollingFuture, future)) {
        _pollingFuture = null;
      }
    });
    return future;
  }

  void _resetPollingContext() {
    _pollGeneration += 1;
    _pollingFuture = null;
  }

  Future<bool> _pollForToken(int generation) async {
    final clientId = _clientId;
    final requestId = _requestId;
    final steamId = _steamId;
    if (clientId == null || requestId == null || steamId == null) {
      errorMessage.value = 'app.user.login.message.error';
      return false;
    }

    const maxAttempts = 30;
    for (var attempt = 0; attempt < maxAttempts; attempt += 1) {
      if (generation != _pollGeneration) {
        _logEvent('poll.cancelled', {
          'attempt': attempt + 1,
          'reason': 'generation_changed',
        });
        return false;
      }
      try {
        final pollRes = await _authClient.pollAuthSessionStatus({
          'client_id': clientId,
          'request_id': requestId,
        });
        final pollData = pollRes['response'] is Map
            ? Map<String, dynamic>.from(pollRes['response'] as Map)
            : <String, dynamic>{};

        final refreshToken = pollData['refresh_token']?.toString();
        final result = pollData['eresult'];
        _logEvent('poll.status', {
          'attempt': attempt + 1,
          'maxAttempts': maxAttempts,
          'topLevelKeys': _mapKeys(pollRes),
          'responseKeys': _mapKeys(pollData),
          'eresult': result,
          'hadRemoteInteraction': pollData['had_remote_interaction'],
          'hasRefreshToken': refreshToken != null && refreshToken.isNotEmpty,
          'refreshTokenLen': refreshToken?.length ?? 0,
        });

        if (refreshToken != null && refreshToken.isNotEmpty) {
          if (generation != _pollGeneration) {
            return false;
          }
          return await _applyRefreshToken(refreshToken);
        }

        if (_isSteamResultError(result)) {
          _logEvent('poll.reject', {
            'attempt': attempt + 1,
            'eresult': result,
          });
          errorMessage.value = 'app.user.login.message.error';
          return false;
        }
      } catch (_) {
        _logEvent('poll.error', {
          'attempt': attempt + 1,
        });
        errorMessage.value = 'app.user.login.message.error';
        return false;
      }

      if (generation != _pollGeneration) {
        return false;
      }
      await Future.delayed(const Duration(seconds: 5));
    }

    _logEvent('poll.timeout', {
      'attempts': maxAttempts,
    });
    errorMessage.value = 'app.user.login.message.error';
    return false;
  }

  Future<bool> _applyRefreshToken(String refreshToken) async {
    final steamId = _steamId;
    if (steamId == null || steamId.isEmpty) {
      _logEvent('tokenFresh.invalidSteamId', {
        'steamId': _maskId(steamId),
      });
      errorMessage.value = 'app.user.login.message.error';
      return false;
    }

    _logEvent('tokenFresh.begin', {
      'steamId': _maskId(steamId),
      'refreshTokenLen': refreshToken.length,
    });

    final res = await _steamApi.steamTokenFresh(
      steamId: steamId,
      freshToken: refreshToken,
    );
    _logEvent('tokenFresh.response', {
      'success': res.success,
      'code': res.code,
      'message': res.message,
      'hasDatas': res.datas != null,
    });
    if (!res.success) {
      final failureMessage = _resolveTokenFreshFailureMessage(res);
      Get.snackbar('app.system.tips.title'.tr, failureMessage);
      accountController.clear();
      passwordController.clear();
      codeController.clear();
      isAwaitingCode.value = false;
      _resetPollingContext();
      errorMessage.value = '';
      return false;
    }

    await SteamStorage.setAccount(accountController.text.trim());
    await SteamStorage.setPassword(passwordController.text);
    codeController.clear();
    isAwaitingCode.value = false;
    _resetPollingContext();
    _logEvent('tokenFresh.success', {
      'storedAccountLen': accountController.text.trim().length,
    });
    return true;
  }

  String _resolveTokenFreshFailureMessage(BaseHttpResponse<dynamic> res) {
    final datasText = res.datas?.toString().trim() ?? '';
    final messageText = res.message.trim();
    final raw = datasText.isNotEmpty ? datasText : messageText;
    if (raw.toLowerCase() == 'unbind steam') {
      return 'app.steam.message.unbind'.tr;
    }
    if (raw.isNotEmpty) {
      return raw;
    }
    return 'Failed';
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

  void _logEvent(String stage, Map<String, dynamic> payload) {
    if (!kDebugMode) {
      return;
    }
    final text = payload.entries.map((entry) {
      return '${entry.key}=${entry.value}';
    }).join(', ');
    debugPrint('[SteamSession][$stage] $text');
  }

  String _mapKeys(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return '[]';
    }
    return '[${data.keys.join('|')}]';
  }

  String _maskId(String? value) {
    if (value == null || value.isEmpty) {
      return 'empty';
    }
    if (value.length <= 4) {
      return '${value[0]}***(${value.length})';
    }
    return '${value.substring(0, 2)}***${value.substring(value.length - 2)}(${value.length})';
  }

  @override
  void onClose() {
    _resetPollingContext();
    accountController.dispose();
    passwordController.dispose();
    codeController.dispose();
    super.onClose();
  }
}
