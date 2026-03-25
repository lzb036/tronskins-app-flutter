import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/loginServer.dart';
import 'package:tronskins_app/common/device/device_id_helper.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/interceptors/auth_interceptor.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/routes/app_routes.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SteamLoginPage extends StatefulWidget {
  const SteamLoginPage({super.key});

  @override
  State<SteamLoginPage> createState() => _SteamLoginPageState();
}

class _SteamLoginPageState extends State<SteamLoginPage> {
  late final WebViewController _controller;
  bool _isPageLoading = true;
  bool _isSubmitting = false;
  String? _lastCallback;
  String? _pendingCallback;

  String get _loginUrl =>
      '${HttpHelper.baseUrl}api/public/steam/auth/login/validate';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() => _isPageLoading = true);
            }
          },
          onPageFinished: (url) {
            // 页面加载完成后检查是否有回调（Steam 登录成功后会重定向回来）
            _handleCallback(url);
            if (mounted) {
              setState(() => _isPageLoading = false);
            }
          },
          onNavigationRequest: (request) {
            // 导航请求时不立即处理，等待 onPageFinished
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));
  }

  void _handleCallback(String url) {
    if (_isSubmitting) {
      return;
    }

    final sanitized = url.replaceAll('#', '%23').replaceAll('+', '%2B');
    final rawCallback = _extractCallbackRaw(sanitized);

    // 只有在 URL 包含有效的 callback 参数时才保存
    if (rawCallback != null &&
        rawCallback.isNotEmpty &&
        _isValidCallback(rawCallback)) {
      _pendingCallback = rawCallback;
    }

    // 只有在 Steam 登录成功页面才提交 callback
    if (!sanitized.contains('login/sso.html')) {
      return;
    }

    final callback = _pendingCallback ?? rawCallback;
    if (callback == null || callback.isEmpty) {
      return;
    }

    // 验证 callback 有效性
    if (!_isValidCallback(callback)) {
      return;
    }

    if (callback == _lastCallback) {
      return;
    }

    _lastCallback = callback;
    _submitCallback(callback);
  }

  /// 验证 callback 是否为有效的 base64 字符串
  /// Steam SSO 返回的 callback 应该是 base64 编码的字符串
  bool _isValidCallback(String callback) {
    if (callback.isEmpty) {
      return false;
    }

    // callback 不应该包含 URL 特殊字符（除了 base64 字符集）
    // 如果包含 : 或 / 等字符，说明可能是 URL 而不是 base64
    if (callback.contains(':') || callback.contains('/')) {
      return false;
    }

    // callback 长度应该大于一定值（base64 编码的数据通常不会太短）
    if (callback.length < 10) {
      return false;
    }

    return true;
  }

  String? _extractCallbackRaw(String value) {
    final callbackIndex = value.indexOf('callback=');
    if (callbackIndex == -1) {
      return null;
    }

    final start = callbackIndex + 'callback='.length;
    if (start >= value.length) {
      return '';
    }

    return value.substring(start);
  }

  Future<void> _submitCallback(String callback) async {
    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await ApiLoginServer().loginSsoSteam(
        callback: callback,
        udid: DeviceIdHelper.getUdid(),
      );

      if (!result.success || result.datas == null) {
        _showError(
          result.message.isNotEmpty
              ? result.message
              : 'app.user.login.message.error'.tr,
        );
        return;
      }

      final payload = result.datas!;
      final tokenValue =
          payload['accessToken']?.toString() ??
          payload['token']?.toString() ??
          '';
      if (tokenValue.isEmpty) {
        _showError('app.user.login.message.error'.tr);
        return;
      }

      await AuthInterceptor.setAccessToken(
        accessToken: tokenValue,
        accessTokenExpireTime: _toInt(payload['accessTokenExpireTime']),
        refreshTokenExpireTime:
            _toInt(payload['refreshTokenExpireTime']) ??
            _toInt(payload['refreshExpireTime']),
        header: payload['header']?.toString(),
      );
      if (!mounted) {
        return;
      }

      Get.offAllNamed(Routers.HOME);
      _showSuccess('app.user.login.message.success'.tr);
    } catch (e) {
      _showError('app.user.login.message.error'.tr);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    AppSnackbar.error(message);
  }

  void _showSuccess(String message) {
    AppSnackbar.success(message);
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  Future<void> _reload() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isPageLoading = true;
      _lastCallback = null;
      _pendingCallback = null;
    });
    await _controller.loadRequest(Uri.parse(_loginUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF171A21),
        title: Text(
          'app.steam.login.title'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1.${'app.steam.message.load_error'.tr}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '2.${'app.steam.message.load_error_2'.tr}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _reload,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF171A21),
                        backgroundColor: const Color(0xFFE9EDF3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'app.common.refresh'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isPageLoading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFF74BCFF),
                  ),
                if (_isSubmitting)
                  Container(
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF171A21),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
