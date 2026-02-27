import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    super.initState();
    controller.loadShop();
  }

  String _formatTime(int? value) {
    if (value == null) {
      return '00';
    }
    if (value < 10) {
      return '0$value';
    }
    return value.toString();
  }

  Future<void> _pickTime() async {
    final shop = controller.shop.value;
    if (shop == null) {
      return;
    }
    final initial = TimeOfDay(
      hour: shop.hour ?? 0,
      minute: shop.minute ?? 0,
    );
    final result = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (result == null) {
      return;
    }
    await controller.setAutoCloseTime(result.hour, result.minute);
    Get.snackbar('app.system.tips.title'.tr, 'app.system.message.success'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.user.shop.setting'.tr),
      ),
      body: Obx(() {
        final shop = controller.shop.value;
        if (shop == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final autoClose = shop.openAutoClose ?? false;
        final autoTime =
            '${_formatTime(shop.hour)}:${_formatTime(shop.minute)}';
        return RefreshIndicator(
          onRefresh: controller.loadShop,
          child: ListView(
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
                      onChanged: (value) async {
                        await controller.toggleShopStatus();
                        await controller.loadShop();
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text('app.user.shop.automatic_offline'.tr),
                      value: autoClose,
                      onChanged: (value) async {
                        await controller.toggleAutoOffline(value);
                        await controller.loadShop();
                      },
                    ),
                    ListTile(
                      title: Text('app.user.shop.deliver_time'.tr),
                      subtitle: Text(autoClose ? autoTime : '--:--'),
                      trailing: const Icon(Icons.schedule),
                      onTap: autoClose ? _pickTime : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
