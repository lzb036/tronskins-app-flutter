import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/controllers/shop/shop_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class ShopSettingPage extends StatefulWidget {
  const ShopSettingPage({super.key});

  @override
  State<ShopSettingPage> createState() => _ShopSettingPageState();
}

class _ShopSettingPageState extends State<ShopSettingPage> {
  final ShopController controller = Get.isRegistered<ShopController>()
      ? Get.find<ShopController>()
      : Get.put(ShopController());
  bool _isSwitchingShopOnline = false;
  bool _isSwitchingAutoOffline = false;

  @override
  void initState() {
    super.initState();
    controller.loadShop();
  }

  Future<bool> _confirmSwitch(String messageKey) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text(messageKey.tr),
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
    return confirmed == true;
  }

  String _shopOnlineConfirmKey(bool value) => value
      ? 'app.user.shop.message.confirm_online_on'
      : 'app.user.shop.message.confirm_online_off';

  String _shopOnlineSuccessKey(bool value) => value
      ? 'app.user.shop.message.online_on_success'
      : 'app.user.shop.message.online_off_success';

  String _shopOnlineFailedKey(bool value) => value
      ? 'app.user.shop.message.online_on_failed'
      : 'app.user.shop.message.online_off_failed';

  String _autoOfflineConfirmKey(bool value) => value
      ? 'app.user.shop.message.confirm_auto_offline_on'
      : 'app.user.shop.message.confirm_auto_offline_off';

  String _autoOfflineSuccessKey(bool value) => value
      ? 'app.user.shop.message.auto_offline_on_success'
      : 'app.user.shop.message.auto_offline_off_success';

  String _autoOfflineFailedKey(bool value) => value
      ? 'app.user.shop.message.auto_offline_on_failed'
      : 'app.user.shop.message.auto_offline_off_failed';

  Future<void> _handleShopOnlineChanged(bool value) async {
    if (_isSwitchingShopOnline) {
      return;
    }
    final confirmed = await _confirmSwitch(_shopOnlineConfirmKey(value));
    if (!confirmed) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _isSwitchingShopOnline = true);
    try {
      final res = await controller.toggleShopStatus();
      if (res.success) {
        AppSnackbar.success(_shopOnlineSuccessKey(value).tr);
      } else {
        AppSnackbar.error(_shopOnlineFailedKey(value).tr);
        await controller.loadShop();
      }
    } catch (_) {
      AppSnackbar.error(_shopOnlineFailedKey(value).tr);
      await controller.loadShop();
    } finally {
      if (mounted) {
        setState(() => _isSwitchingShopOnline = false);
      }
    }
  }

  Future<void> _handleAutoOfflineChanged(bool value) async {
    if (_isSwitchingAutoOffline) {
      return;
    }
    final confirmed = await _confirmSwitch(_autoOfflineConfirmKey(value));
    if (!confirmed) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _isSwitchingAutoOffline = true);
    try {
      final res = await controller.toggleAutoOffline(value);
      if (res.success) {
        AppSnackbar.success(_autoOfflineSuccessKey(value).tr);
      } else {
        AppSnackbar.error(_autoOfflineFailedKey(value).tr);
        await controller.loadShop();
      }
    } catch (_) {
      AppSnackbar.error(_autoOfflineFailedKey(value).tr);
      await controller.loadShop();
    } finally {
      if (mounted) {
        setState(() => _isSwitchingAutoOffline = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('app.user.shop.setting'.tr)),
      body: Obx(() {
        final shop = controller.shop.value;
        if (shop == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final autoClose = shop.openAutoClose ?? false;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('app.user.shop.notice'.tr),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('app.user.shop.name.label'.tr),
                    subtitle: Text(shop.shopName ?? shop.name ?? '-'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(Routers.SHOP_RENAME),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text('app.user.shop.online_title'.tr),
                    value: shop.isOnline ?? false,
                    onChanged: _isSwitchingShopOnline
                        ? null
                        : _handleShopOnlineChanged,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text('app.user.shop.automatic_offline'.tr),
                    value: autoClose,
                    onChanged: _isSwitchingAutoOffline
                        ? null
                        : _handleAutoOfflineChanged,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
