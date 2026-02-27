import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/storage/server_storage.dart';
import 'package:restart_app/restart_app.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({super.key});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  List<String> servers = <String>[];
  String current = '';

  @override
  void initState() {
    super.initState();
    servers = ServerStorage.getServerList();
    current = ServerStorage.getServer();
  }

  Future<void> _addServer() async {
    final TextEditingController input = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('app.user.setting.server_add'.tr),
          content: TextField(
            controller: input,
            decoration: InputDecoration(
              hintText: 'app.user.setting.server_ip_placeholder'.tr,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('app.common.cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                final value = input.text.trim();
                if (!_isValidServer(value)) {
                  Get.snackbar(
                    'app.system.tips.title'.tr,
                    'app.user.server.message.address_invalid'.tr,
                  );
                  return;
                }
                Navigator.pop(context, value);
              },
              child: Text('app.common.confirm'.tr),
            ),
          ],
        );
      },
    );
    if (result == null || result.isEmpty) {
      return;
    }
    final normalized = _normalize(result);
    if (servers.contains(normalized)) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.setting.server_exists'.tr,
      );
      return;
    }
    setState(() {
      servers.add(normalized);
    });
    ServerStorage.setServerList(servers);
    Get.snackbar('app.system.tips.title'.tr, 'app.user.setting.server_add'.tr);
  }

  Future<void> _deleteServer(String server) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.user.server.message.confirm_delete'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('app.common.cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('app.common.confirm'.tr),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        servers.remove(server);
      });
      ServerStorage.setServerList(servers);
    }
  }

  Future<void> _switchServer(String server) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text(
          '${'app.user.setting.server_switching_confirm'.tr} $server',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('app.common.cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('app.common.confirm'.tr),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _showConnectivityLoading();
      final reachable = await _checkServerConnectivity(server);
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      if (!mounted) {
        return;
      }
      if (!reachable) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.user.setting.server_connectivity_failed'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.setting.server_connectivity_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      setState(() => current = server);
      ServerStorage.setServer(server);
      HttpHelper.setBaseUrl(server);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) {
        return;
      }
      Restart.restartApp();
    }
  }

  void _showConnectivityLoading() {
    Get.dialog(
      AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('app.user.setting.server_connectivity_testing'.tr),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<bool> _checkServerConnectivity(String server) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: server,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        responseType: ResponseType.json,
        validateStatus: (_) => true,
      ),
    );
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      if (!kReleaseMode) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      }
      return client;
    };
    try {
      final appId = GameStorage.getGameType();
      final response = await dio.post(
        'api/public/mall/sell/$appId/news',
        data: {
          'appId': appId,
          'page': 1,
          'pageSize': 1,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      dio.close(force: true);
    }
  }

  bool _isValidServer(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        (uri.host.isNotEmpty);
  }

  String _normalize(String value) => value.endsWith('/') ? value : '$value/';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tileRadius = BorderRadius.circular(14);

    return Scaffold(
      appBar: AppBar(
        title: Text('app.user.setting.server'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addServer,
          ),
        ],
      ),
      body: servers.isEmpty
          ? Center(child: Text('app.common.no_data'.tr))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: servers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final server = servers[index];
                final isCurrent = server == current;
                final cardColor = isCurrent
                    ? (Color.lerp(
                          colorScheme.primaryContainer,
                          colorScheme.primary.withOpacity(0.08),
                          0.4,
                        ) ??
                        colorScheme.primaryContainer)
                    : colorScheme.surface;
                final borderColor = isCurrent
                    ? colorScheme.primary.withOpacity(isDark ? 0.45 : 0.35)
                    : colorScheme.outlineVariant.withOpacity(isDark ? 0.5 : 0.7);
                final leadingBg = isCurrent
                    ? colorScheme.primary.withOpacity(isDark ? 0.2 : 0.12)
                    : colorScheme.surfaceVariant;
                final leadingFg =
                    isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant;

                return Material(
                  color: cardColor,
                  elevation: isCurrent ? 2 : 0,
                  shadowColor: isCurrent
                      ? colorScheme.primary.withOpacity(isDark ? 0.35 : 0.25)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: tileRadius,
                    side: BorderSide(color: borderColor),
                  ),
                  child: ListTile(
                    enabled: true,
                    shape: RoundedRectangleBorder(borderRadius: tileRadius),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: leadingBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCurrent
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_outlined,
                        color: leadingFg,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      server,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCurrent)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteServer(server),
                            tooltip: MaterialLocalizations.of(context)
                                .deleteButtonTooltip,
                            splashRadius: 20,
                            visualDensity: VisualDensity.compact,
                          ),
                        Icon(
                          isCurrent
                              ? Icons.check_circle_rounded
                              : Icons.chevron_right_rounded,
                          color: isCurrent
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: isCurrent ? null : () => _switchServer(server),
                  ),
                );
              },
            ),
    );
  }
}
