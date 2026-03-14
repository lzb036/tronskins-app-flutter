import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/controllers/auth/steam_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class SteamSettingPage extends StatefulWidget {
  const SteamSettingPage({super.key});

  @override
  State<SteamSettingPage> createState() => _SteamSettingPageState();
}

class _SteamSettingPageState extends State<SteamSettingPage> {
  final SteamController controller = Get.put(SteamController());
  final TextEditingController tradeUrlController = TextEditingController();
  final TextEditingController apiKeyController = TextEditingController();
  late final Worker _configWorker;

  @override
  void initState() {
    super.initState();
    tradeUrlController.text = controller.tradeUrl.value;
    apiKeyController.text = controller.apiKey.value;
    _configWorker = ever(controller.config, (_) {
      tradeUrlController.text = controller.tradeUrl.value;
      apiKeyController.text = controller.apiKey.value;
    });

    // Check for Steam ID mismatch argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadSteamConfig();
      final args = Get.arguments;
      if (args is Map<String, dynamic> && args['showSteamIdNotMatch'] == true) {
        _showSteamIdMismatchDialog();
      }
    });
  }

  @override
  void dispose() {
    _configWorker.dispose();
    tradeUrlController.dispose();
    apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _bindSteam() async {
    final token = await controller.getTemporaryToken();
    if (token == null) {
      _showSnack('app.user.login.message.error'.tr);
      return;
    }
    Get.toNamed(Routers.STEAM_BIND, arguments: token);
  }

  Future<void> _toSteamSession() async {
    final result = await Get.toNamed(Routers.STEAM_SESSION);
    if (result == true) {
      await controller.loadSteamConfig();
    }
  }

  Future<void> _openTradeUrlPage(String steamId) async {
    await Get.toNamed(Routers.STEAM_TRADE_URL, arguments: steamId);
    await controller.loadSteamConfig();
  }

  Future<void> _openApiKeyPage() async {
    await Get.toNamed(Routers.STEAM_API_KEY);
    await controller.loadSteamConfig();
  }

  void _showSteamIdMismatchDialog() {
    final config = controller.config.value;
    final nickname = (config?.nickname ?? '').trim().isNotEmpty
        ? (config?.nickname ?? '').trim()
        : controller.userNickname.value;
    Get.dialog(
      AlertDialog(
        title: Text('app.steam.message.account_not_match'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (config?.avatar != null)
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(config!.avatar!),
                radius: 30,
              ),
            const SizedBox(height: 12),
            if (nickname.isNotEmpty) Text(nickname),
            const SizedBox(height: 8),
            Text('Steam ID: ${config?.steamId ?? ''}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('app.common.confirm'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _unbindSteam() async {
    final canUnbind = await controller.canUnbind();
    if (!canUnbind) {
      _showSnack('app.user.login.message.error'.tr);
      return;
    }
    Get.dialog(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.steam.account.unbind_tips'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('app.common.cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.toNamed(Routers.STEAM_UNBIND);
            },
            child: Text('app.common.confirm'.tr),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    Get.snackbar(
      'app.system.tips.title'.tr,
      message,
      backgroundColor: Theme.of(context).colorScheme.primary,
      colorText: Theme.of(context).colorScheme.onPrimary,

      titleText: const SizedBox.shrink(),
    );
  }

  Future<void> _copySteamId(String steamId) async {
    await Clipboard.setData(ClipboardData(text: steamId));
    _showSnack('app.system.message.copy_success'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('app.steam.account.management'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined),
            tooltip: 'app.steam.verification'.tr,
            onPressed: _toSteamSession,
          ),
        ],
      ),
      body: BackToTopScope(
        enabled: false,
        child: Obx(() {
          final config = controller.config.value;
          final steamId = config?.steamId ?? '';
          final avatar = config?.avatar ?? '';
          final steamNickname = (config?.nickname ?? '').trim();
          final fallbackNickname = controller.userNickname.value.trim();
          final nickname = steamNickname.isNotEmpty
              ? steamNickname
              : fallbackNickname;
          final hasNickname = nickname.isNotEmpty && nickname != '-';
          final tradeStatus = controller.tradeStatus.value;
          final showSteamIdLoading =
              controller.isLoading.value && steamId.isEmpty;
          final isTradeStatusLoading = tradeStatus == null;
          final isBound = steamId.isNotEmpty;

          Widget steamIdContent;
          if (showSteamIdLoading) {
            steamIdContent = Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'app.steam.message.loading_steam_id'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            );
          } else if (isBound) {
            steamIdContent = Row(
              children: [
                Expanded(
                  child: Text(
                    'STEAM ID: $steamId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            );
          } else {
            steamIdContent = Text(
              'app.steam.message.unbind'.tr,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
                  colorScheme.surface,
                ],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Card(
                  elevation: 0,
                  shape: cardShape,
                  color: colorScheme.surface,
                  child: InkWell(
                    onTap: isBound ? () => _copySteamId(steamId) : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  backgroundImage: avatar.isNotEmpty
                                      ? CachedNetworkImageProvider(avatar)
                                      : const AssetImage(
                                              'assets/images/user/none.png',
                                            )
                                            as ImageProvider,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasNickname ? nickname : 'Steam',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    steamIdContent,
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: isBound
                                ? FilledButton.tonal(
                                    onPressed: config == null
                                        ? null
                                        : _unbindSteam,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('app.steam.account.unbind'.tr),
                                  )
                                : FilledButton(
                                    onPressed: config == null
                                        ? null
                                        : _bindSteam,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('app.steam.account.bind'.tr),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: cardShape,
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'app.steam.account.status_label'.tr,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: controller.refreshTradeStatus,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text('app.common.refresh'.tr),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (isTradeStatusLoading)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'app.steam.message.loading_account_status'
                                        .tr,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tradeStatus
                                  ? colorScheme.secondaryContainer
                                  : colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  tradeStatus
                                      ? Icons.verified_outlined
                                      : Icons.error_outline,
                                  color: tradeStatus
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tradeStatus
                                        ? 'app.steam.account.status_success'.tr
                                        : 'app.steam.account.status_error'.tr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: tradeStatus
                                          ? colorScheme.onSecondaryContainer
                                          : colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!controller.sessionValid.value && isBound) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer.withValues(
                                alpha: 0.55,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'app.steam.session.expired'.tr,
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: cardShape,
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'app.steam.tradeLink_text'.tr,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: tradeUrlController,
                          onChanged: (value) =>
                              controller.tradeUrl.value = value,
                          decoration: InputDecoration(
                            hintText: 'app.steam.tradeLink_text'.tr,
                            prefixIcon: const Icon(Icons.link_rounded),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: inputBorder,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.4,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: steamId.isEmpty
                                  ? null
                                  : () => _openTradeUrlPage(steamId),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'app.steam.api_key.setting'.tr,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: apiKeyController,
                          onChanged: (value) => controller.apiKey.value = value,
                          decoration: InputDecoration(
                            hintText: 'app.steam.api_key.setting'.tr,
                            prefixIcon: const Icon(Icons.vpn_key_rounded),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: inputBorder,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.4,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: _openApiKeyPage,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: controller.hasChanges
                                ? () async {
                                    await controller.saveChanges();
                                    _showSnack('app.system.message.success'.tr);
                                  }
                                : null,
                            child: controller.isSaving.value
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('app.common.save'.tr),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: cardShape,
                  color: colorScheme.surface,
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.7),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text('app.steam.settings.inventory'.tr),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: steamId.isEmpty
                        ? null
                        : () => Get.toNamed(
                            Routers.STEAM_INVENTORY_SETTING,
                            arguments: steamId,
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
