import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/controllers/auth/steam_controller.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';
import 'package:tronskins_app/pages/steam/steam_session_injection.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SteamSessionPage extends StatefulWidget {
  const SteamSessionPage({super.key});

  @override
  State<SteamSessionPage> createState() => _SteamSessionPageState();
}

class _SteamSessionPageState extends State<SteamSessionPage> {
  static const String _bridgeChannelName = 'TronSteamSession';
  static const String _titleSteamIdSeparator = '&steamId=';

  final ApiSteamServer _steamApi = ApiSteamServer();
  final WebViewCookieManager _cookieManager = WebViewCookieManager();

  late final WebViewController _controller;
  Timer? _titlePoller;

  bool _isPageLoading = true;
  bool _isSavingToken = false;
  bool _observerInjected = false;
  bool _hasHandledToken = false;
  bool _hasPendingTokenPayload = false;
  bool _isReadingTitle = false;
  bool _hasTriedFreshStart = false;

  late final String _boundSteamId;

  String get _sessionUrl =>
      'https://steamcommunity.com/login/home/?l=${_steamLanguageCode()}';

  bool get _isChinese =>
      (Get.locale?.languageCode ?? '').toLowerCase().startsWith('zh');

  String get _savingTokenLabel =>
      _isChinese ? '正在更新 Steam 会话...' : 'Updating Steam session...';

  @override
  void initState() {
    super.initState();
    _boundSteamId = _resolveBoundSteamId();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        _bridgeChannelName,
        onMessageReceived: (message) {
          _handleBridgeMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            _observerInjected = false;
            if (mounted) {
              setState(() => _isPageLoading = true);
            }
          },
          onPageFinished: (_) async {
            final restarted = await _ensureFreshStartIfNeeded();
            if (restarted) {
              return;
            }

            await _injectObserver();
            _startTitlePolling();
            await _readRefreshTokenFromTitle();
            if (mounted) {
              setState(() => _isPageLoading = false);
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() => _isPageLoading = false);
            }
          },
          onNavigationRequest: (request) {
            if ((_hasPendingTokenPayload ||
                    _isSavingToken ||
                    _hasHandledToken) &&
                _isSteamPostLoginUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    Future.microtask(_startFreshSession);
  }

  @override
  void dispose() {
    _titlePoller?.cancel();
    super.dispose();
  }

  String _resolveBoundSteamId() {
    final args = Get.arguments;
    if (args is String) {
      return args.trim();
    }
    if (args is Map) {
      final steamId = args['steamId'];
      if (steamId != null) {
        return steamId.toString().trim();
      }
    }
    if (Get.isRegistered<SteamController>()) {
      final config = Get.find<SteamController>().config.value;
      return (config?.steamId ?? '').trim();
    }
    if (Get.isRegistered<UserController>()) {
      final steamId = Get.find<UserController>().user.value?.config?.steamId;
      return (steamId ?? '').trim();
    }
    return '';
  }

  String _steamLanguageCode() {
    final locale = Get.locale;
    final language = (locale?.languageCode ?? '').toLowerCase();
    final country = (locale?.countryCode ?? '').toUpperCase();

    if (language == 'zh' && country == 'TW') {
      return 'tchinese';
    }

    switch (language) {
      case 'zh':
        return 'schinese';
      case 'ja':
        return 'japanese';
      case 'ko':
        return 'koreana';
      case 'fr':
        return 'french';
      case 'de':
        return 'german';
      case 'id':
        return 'indonesian';
      case 'it':
        return 'italian';
      case 'pl':
        return 'polish';
      case 'pt':
        return 'portuguese';
      case 'ru':
        return 'russian';
      case 'es':
        return 'spanish';
      case 'th':
        return 'thai';
      case 'tr':
        return 'turkish';
      case 'vi':
        return 'vietnamese';
      default:
        return 'english';
    }
  }

  void _startTitlePolling() {
    if (_titlePoller != null) {
      return;
    }

    _titlePoller = Timer.periodic(const Duration(seconds: 1), (_) {
      _readRefreshTokenFromTitle();
    });
  }

  Future<bool> _ensureFreshStartIfNeeded() async {
    if (_hasTriedFreshStart) {
      return false;
    }
    _hasTriedFreshStart = true;

    try {
      final result = await _controller.runJavaScriptReturningResult('''
(() => {
  const href = window.location.href || '';
  const hasLoggedInMarker = !!(
    (typeof window.g_steamID !== 'undefined' &&
      window.g_steamID &&
      window.g_steamID !== false) ||
    document.querySelector('[data-miniprofile]') ||
    document.querySelector('.persona_name_text_content') ||
    href.indexOf('/profiles/') !== -1 ||
    href.indexOf('/id/') !== -1
  );
  return hasLoggedInMarker && typeof window.Logout === 'function'
    ? 'logout'
    : 'continue';
})();
''');

      if (_normalizeJsString(result) != 'logout') {
        return false;
      }

      final sessionUrl = jsonEncode(_sessionUrl);
      await _controller.runJavaScript('''
(() => {
  try {
    window.Logout();
  } catch (error) {}
  setTimeout(function() {
    try {
      window.location.href = $sessionUrl;
    } catch (error) {}
  }, 1200);
})();
''');
      return true;
    } catch (_) {
      return false;
    }
  }

  String _normalizeJsString(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }
    if (raw.startsWith('"') && raw.endsWith('"')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is String) {
          return decoded.trim();
        }
      } catch (_) {}
    }
    return raw;
  }

  bool _isSteamPostLoginUrl(String? url) {
    final rawUrl = url?.trim().toLowerCase() ?? '';
    if (rawUrl.isEmpty) {
      return false;
    }

    return rawUrl.contains('steamcommunity.com/my') ||
        rawUrl.contains('steamcommunity.com/profiles/') ||
        rawUrl.contains('steamcommunity.com/id/');
  }

  Future<void> _startFreshSession() async {
    _titlePoller?.cancel();
    _titlePoller = null;

    if (mounted) {
      setState(() {
        _observerInjected = false;
        _hasHandledToken = false;
        _hasPendingTokenPayload = false;
        _hasTriedFreshStart = false;
        _isSavingToken = false;
        _isPageLoading = true;
      });
    }

    try {
      await _cookieManager.clearCookies();
    } catch (_) {}

    try {
      await _controller.clearLocalStorage();
    } catch (_) {}

    try {
      await _controller.clearCache();
    } catch (_) {}

    try {
      await _controller.loadRequest(Uri.parse(_sessionUrl));
    } catch (_) {
      if (mounted) {
        setState(() => _isPageLoading = false);
      }
    }
  }

  Future<void> _injectObserver() async {
    if (_observerInjected) {
      return;
    }

    try {
      await _controller.runJavaScript(steamSessionInjectionScript);
      _observerInjected = true;
    } catch (_) {}
  }

  Future<void> _handleBridgeMessage(String rawMessage) async {
    if (_hasHandledToken || _isSavingToken || rawMessage.trim().isEmpty) {
      return;
    }

    final payload = _extractTokenPayloadFromBridge(rawMessage);
    if (payload == null) {
      return;
    }

    _hasPendingTokenPayload = true;
    await _saveToken(
      refreshToken: payload['refreshToken'] ?? '',
      loginSteamId: payload['steamId'] ?? '',
    );
  }

  Future<void> _readRefreshTokenFromTitle() async {
    if (_isReadingTitle || _hasHandledToken || !mounted) {
      return;
    }

    _isReadingTitle = true;
    try {
      final title = await _controller.getTitle();
      final payload = _extractTokenPayloadFromTitle(title);
      if (payload == null) {
        return;
      }

      await _saveToken(
        refreshToken: payload['refreshToken'] ?? '',
        loginSteamId: payload['steamId'] ?? '',
      );
    } catch (_) {
    } finally {
      _isReadingTitle = false;
    }
  }

  Map<String, String>? _extractTokenPayloadFromTitle(String? title) {
    final rawTitle = title?.trim() ?? '';
    if (rawTitle.isEmpty || !rawTitle.startsWith('ey')) {
      return null;
    }

    var refreshToken = rawTitle;
    var steamId = '';
    final separatorIndex = rawTitle.indexOf(_titleSteamIdSeparator);
    if (separatorIndex >= 0) {
      refreshToken = rawTitle.substring(0, separatorIndex).trim();
      steamId = rawTitle
          .substring(separatorIndex + _titleSteamIdSeparator.length)
          .trim();
    }

    if (refreshToken.isEmpty) {
      return null;
    }

    return <String, String>{'refreshToken': refreshToken, 'steamId': steamId};
  }

  Map<String, String>? _extractTokenPayloadFromBridge(String rawMessage) {
    final raw = rawMessage.trim();
    if (raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final refreshToken = _readText(decoded['refreshToken']);
        if (refreshToken.isEmpty) {
          return null;
        }
        return <String, String>{
          'refreshToken': refreshToken,
          'steamId': _readText(decoded['steamId']),
        };
      }
    } catch (_) {}

    return _extractTokenPayloadFromTitle(raw);
  }

  Future<void> _saveToken({
    required String refreshToken,
    required String loginSteamId,
  }) async {
    if (_hasHandledToken || _isSavingToken) {
      return;
    }

    if (_boundSteamId.isEmpty) {
      _hasPendingTokenPayload = false;
      _showError('app.steam.message.unbind'.tr);
      return;
    }

    if (loginSteamId.isNotEmpty && loginSteamId != _boundSteamId) {
      _hasHandledToken = true;
      _titlePoller?.cancel();
      _titlePoller = null;
      Get.back(
        result: {
          'showSteamIdNotMatch': true,
          'steamId': _boundSteamId,
          'loginSteamId': loginSteamId,
        },
      );
      return;
    }

    if (mounted) {
      setState(() => _isSavingToken = true);
    }
    _hasHandledToken = true;
    _logMaskedRefreshToken(
      refreshToken: refreshToken,
      loginSteamId: loginSteamId,
    );

    try {
      final result = await _steamApi.steamTokenFresh(
        steamId: _boundSteamId,
        freshToken: refreshToken,
      );
      if (!mounted) {
        return;
      }

      if (!result.success) {
        _hasHandledToken = false;
        _hasPendingTokenPayload = false;
        _showError(_resolveTokenFreshFailureMessage(result));
        return;
      }

      if (Get.isRegistered<SteamController>()) {
        final steamController = Get.find<SteamController>();
        steamController.sessionValid.value = true;
        await steamController.loadSteamConfig();
      }
      if (!mounted) {
        return;
      }

      _titlePoller?.cancel();
      _titlePoller = null;
      Get.back(
        result: {
          'verified': true,
          'sessionValid': true,
          'steamId': _boundSteamId,
          'loginSteamId': loginSteamId.isNotEmpty
              ? loginSteamId
              : _boundSteamId,
          'refreshToken': refreshToken,
          'serverData': result.datas,
        },
      );
      AppSnackbar.success('app.steam.message.verify_success'.tr);
    } catch (_) {
      _hasHandledToken = false;
      _hasPendingTokenPayload = false;
      _showError('app.user.login.message.error'.tr);
    } finally {
      if (mounted) {
        setState(() => _isSavingToken = false);
      }
    }
  }

  String _resolveTokenFreshFailureMessage(BaseHttpResponse<dynamic> result) {
    final dataText = _readText(result.datas);
    final messageText = _readText(result.message);
    final raw = dataText.isNotEmpty ? dataText : messageText;
    if (raw.toLowerCase() == 'unbind steam') {
      return 'app.steam.message.unbind'.tr;
    }
    if (raw.isNotEmpty) {
      return raw;
    }
    return 'app.user.login.message.error'.tr;
  }

  String _readText(dynamic value) => value?.toString().trim() ?? '';

  void _logMaskedRefreshToken({
    required String refreshToken,
    required String loginSteamId,
  }) {
    final normalizedToken = refreshToken.trim();
    final maskedPrefix = normalizedToken.length <= 12
        ? normalizedToken
        : normalizedToken.substring(0, 12);
    final resolvedSteamId = loginSteamId.isNotEmpty
        ? loginSteamId
        : _boundSteamId;

    debugPrint(
      '[STEAM][TOKEN_CAPTURED] steamId=$resolvedSteamId '
      'tokenLength=${normalizedToken.length} tokenPrefix=$maskedPrefix',
    );
  }

  void _showError(String message) {
    AppSnackbar.error(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF171A21),
        title: Text(
          'app.steam.verification'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isPageLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF74BCFF),
            ),
          if (_isSavingToken)
            Container(
              color: Colors.black12,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF171A21)),
                    const SizedBox(height: 12),
                    Text(
                      _savingTokenLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF171A21),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
