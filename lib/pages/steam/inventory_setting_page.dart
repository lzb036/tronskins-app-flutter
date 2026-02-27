import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InventorySettingPage extends StatefulWidget {
  const InventorySettingPage({super.key});

  @override
  State<InventorySettingPage> createState() => _InventorySettingPageState();
}

class _InventorySettingPageState extends State<InventorySettingPage> {
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
      _controller.loadRequest(Uri.parse(_inventoryUrl));
    }
  }

  Future<void> _reload() async {
    if (_steamId == null || _steamId!.isEmpty) {
      return;
    }
    setState(() => _isPageLoading = true);
    await _controller.loadRequest(Uri.parse(_inventoryUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.steam.settings.inventory'.tr),
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
                if (_steamId != null && _steamId!.isNotEmpty)
                  WebViewWidget(controller: _controller)
                else
                  Center(child: Text('app.user.login.message.error'.tr)),
                if (_isPageLoading)
                  const LinearProgressIndicator(minHeight: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
