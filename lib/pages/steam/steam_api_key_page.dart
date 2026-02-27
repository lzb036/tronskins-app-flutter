import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SteamApiKeyPage extends StatefulWidget {
  const SteamApiKeyPage({super.key});

  @override
  State<SteamApiKeyPage> createState() => _SteamApiKeyPageState();
}

class _SteamApiKeyPageState extends State<SteamApiKeyPage> {
  late final WebViewController _controller;
  bool _isPageLoading = true;

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
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isPageLoading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://steamcommunity.com/dev/apikey'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.steam.api_key.setting'.tr),
        backgroundColor: const Color(0xFF171A21),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isPageLoading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
