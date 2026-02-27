import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
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
  late final WebViewController _controller;
  bool _isPageLoading = true;
  String? _token;

  String get _unbindUrl =>
      '${HttpHelper.baseUrl}api/public/steam/auth/unbind/validate?token=$_token';

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
    _loadToken();
  }

  Future<void> _loadToken() async {
    final res = await _steamApi.getTemporaryToken();
    if (res.success && res.datas != null && res.datas!.isNotEmpty) {
      _token = res.datas;
      await _controller.loadRequest(Uri.parse(_unbindUrl));
      return;
    }
    if (mounted) {
      setState(() => _isPageLoading = false);
    }
  }

  Future<void> _reload() async {
    if (_token == null || _token!.isEmpty) {
      await _loadToken();
      return;
    }
    setState(() => _isPageLoading = true);
    await _controller.loadRequest(Uri.parse(_unbindUrl));
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
