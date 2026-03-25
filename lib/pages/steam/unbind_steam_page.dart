import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/utils/steam_webview_english.dart';
import 'package:tronskins_app/controllers/navbar/nav_controller.dart';
import 'package:tronskins_app/controllers/auth/steam_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UnbindSteamPage extends StatefulWidget {
  const UnbindSteamPage({super.key});

  @override
  State<UnbindSteamPage> createState() => _UnbindSteamPageState();
}

class _UnbindSteamPageState extends State<UnbindSteamPage> {
  final ApiSteamServer _steamApi = ApiSteamServer();
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  late final WebViewController _controller;
  bool _isPageLoading = true;
  bool _tokenLoadFailed = false;
  String? _token;

  String get _unbindUrl =>
      '${HttpHelper.baseUrl}api/public/steam/auth/unbind/validate?token=$_token';

  bool get _returnToInventory {
    final args = Get.arguments;
    return args is Map && args['returnToInventory'] == true;
  }

  Future<void> _returnToUserSetting() async {
    if (Get.isRegistered<SteamController>()) {
      await Get.find<SteamController>().loadSteamConfig();
    }

    var foundUserSetting = false;
    Get.until((route) {
      final routeName = route.settings.name;
      if (routeName == Routers.USER_SETTING) {
        foundUserSetting = true;
        return true;
      }
      return routeName == Routers.HOME;
    });

    if (!foundUserSetting && Get.currentRoute != Routers.USER_SETTING) {
      await Get.toNamed(Routers.USER_SETTING);
    }
  }

  Future<void> _returnToInventoryPage() async {
    if (Get.isRegistered<SteamController>()) {
      await Get.find<SteamController>().loadSteamConfig();
    }

    if (Get.isRegistered<NavController>()) {
      Get.find<NavController>().switchTo(NavController.tabInventory);
    }

    var foundHome = false;
    Get.until((route) {
      final routeName = route.settings.name;
      if (routeName == Routers.HOME) {
        foundHome = true;
        return true;
      }
      return route.isFirst;
    });

    if (!foundHome) {
      await Get.offAllNamed(Routers.HOME);
      if (Get.isRegistered<NavController>()) {
        Get.find<NavController>().switchTo(NavController.tabInventory);
      }
    }
  }

  Future<void> _returnAfterUnbind() async {
    if (_returnToInventory) {
      await _returnToInventoryPage();
      return;
    }
    await _returnToUserSetting();
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isPageLoading = true);
            }
          },
          onPageFinished: (url) async {
            if (url.contains('/user-center/index.html')) {
              await _returnAfterUnbind();
              return;
            }
            if (mounted) {
              setState(() => _isPageLoading = false);
            }
          },
        ),
      );
    _loadToken();
  }

  Future<void> _loadToken() async {
    if (mounted) {
      setState(() {
        _isPageLoading = true;
        _tokenLoadFailed = false;
      });
    }

    final res = await _steamApi.getTemporaryToken();
    if (res.success && res.datas != null && res.datas!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _token = res.datas;
          _tokenLoadFailed = false;
        });
      } else {
        _token = res.datas;
      }
      await SteamWebViewEnglish.load(_controller, _cookieManager, _unbindUrl);
      return;
    }
    if (mounted) {
      setState(() {
        _tokenLoadFailed = true;
        _isPageLoading = false;
      });
    }
  }

  Future<void> _reload() async {
    if (_token == null || _token!.isEmpty) {
      await _loadToken();
      return;
    }
    setState(() => _isPageLoading = true);
    await SteamWebViewEnglish.load(_controller, _cookieManager, _unbindUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.steam.account.unbind_title'.tr),
        backgroundColor: const Color(0xFF171A21),
        foregroundColor: Colors.white,
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
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '2.${'app.steam.message.load_error_2'.tr}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _reload,
                      child: Text('app.common.refresh'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (_token != null && _token!.isNotEmpty)
                  WebViewWidget(controller: _controller)
                else if (_tokenLoadFailed)
                  Center(child: Text('app.user.login.message.error'.tr))
                else
                  const SizedBox.shrink(),
                if (_isPageLoading) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
