import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/utils/steam_webview_english.dart';
import 'package:tronskins_app/controllers/auth/steam_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BindSteamPage extends StatefulWidget {
  const BindSteamPage({super.key});

  @override
  State<BindSteamPage> createState() => _BindSteamPageState();
}

class _BindSteamPageState extends State<BindSteamPage> {
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  late final WebViewController _controller;
  bool _isPageLoading = true;
  String? _token;

  String get _bindUrl =>
      '${HttpHelper.baseUrl}api/public/steam/auth/bind/validate?token=$_token';

  @override
  void initState() {
    super.initState();
    _token = Get.arguments as String?;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isPageLoading = true);
            }
          },
          onPageFinished: (url) {
            if (url.contains('/user-center/index.html')) {
              Get.find<SteamController>().loadSteamConfig();
              Get.offNamed(Routers.STEAM_SETTING);
              return;
            }
            if (mounted) {
              setState(() => _isPageLoading = false);
            }
          },
        ),
      );

    if (_token != null && _token!.isNotEmpty) {
      Future.microtask(_loadBindPage);
    }
  }

  Future<void> _loadBindPage() async {
    await SteamWebViewEnglish.load(_controller, _cookieManager, _bindUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.steam.account.bind_title'.tr),
        backgroundColor: const Color(0xFF171A21),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_token != null && _token!.isNotEmpty)
            WebViewWidget(controller: _controller)
          else
            Center(child: Text('app.user.login.message.error'.tr)),
          if (_isPageLoading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
