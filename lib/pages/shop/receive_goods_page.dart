import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReceiveGoodsPage extends StatefulWidget {
  const ReceiveGoodsPage({super.key});

  @override
  State<ReceiveGoodsPage> createState() => _ReceiveGoodsPageState();
}

class _ReceiveGoodsPageState extends State<ReceiveGoodsPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  String _buildUrl() {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final tradeOfferId = args['tradeOfferId']?.toString() ?? '';
    if (tradeOfferId.isEmpty) {
      return 'https://steamcommunity.com/tradeoffer/';
    }
    return 'https://steamcommunity.com/tradeoffer/$tradeOfferId/';
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
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_buildUrl()));
  }

  Future<void> _reload() async {
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = true);
    await _controller.loadRequest(Uri.parse(_buildUrl()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF171A21),
        title: Text(
          'app.market.product.receive'.tr,
          style: const TextStyle(color: Colors.white),
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
                if (_isLoading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFF74BCFF),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
