import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/utils/steam_webview_english.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InventorySettingPage extends StatefulWidget {
  const InventorySettingPage({super.key});

  @override
  State<InventorySettingPage> createState() => _InventorySettingPageState();
}

class _InventorySettingPageState extends State<InventorySettingPage> {
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  late final WebViewController _controller;
  bool _isPageLoading = true;
  String? _steamId;

  String get _inventoryUrl =>
      'https://steamcommunity.com/profiles/$_steamId/edit/settings/';

  @override
  void initState() {
    super.initState();
    _steamId = Get.arguments as String?;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isPageLoading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isPageLoading = false);
            }
          },
        ),
      );
    if (_steamId != null && _steamId!.isNotEmpty) {
      Future.microtask(_loadInventoryPage);
    }
  }

  Future<void> _loadInventoryPage() async {
    await SteamWebViewEnglish.load(_controller, _cookieManager, _inventoryUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.steam.settings.inventory'.tr),
        backgroundColor: const Color(0xFF171A21),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_steamId != null && _steamId!.isNotEmpty)
            WebViewWidget(controller: _controller)
          else
            Center(child: Text('app.user.login.message.error'.tr)),
          if (_isPageLoading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
