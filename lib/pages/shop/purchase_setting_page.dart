import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/controllers/shop/buy_request_controller.dart';

class PurchaseSettingPage extends StatelessWidget {
  const PurchaseSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<BuyRequestController>()
        ? Get.find<BuyRequestController>()
        : Get.put(BuyRequestController());
    return Scaffold(
      appBar: AppBar(title: Text('app.trade.purchase.setting'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'app.trade.purchase.tips'.tr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final isOnline = controller.purchaseOnline.value;
            return Card(
              child: SwitchListTile(
                title: Text('app.trade.purchase.status_online'.tr),
                value: isOnline,
                onChanged: (_) async {
                  final ok = await controller.togglePurchaseStatus();
                  if (!ok) {
                    Get.snackbar(
                      'app.system.tips.title'.tr,
                      'app.system.message.operation_failed'.tr,
                    );
                  } else {
                    Get.snackbar(
                      'app.system.tips.title'.tr,
                      'app.system.message.success'.tr,
                    );
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
