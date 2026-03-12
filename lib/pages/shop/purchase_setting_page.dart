import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:tronskins_app/controllers/shop/buy_request_controller.dart';

class PurchaseSettingPage extends StatefulWidget {
  const PurchaseSettingPage({super.key});

  @override
  State<PurchaseSettingPage> createState() => _PurchaseSettingPageState();
}

class _PurchaseSettingPageState extends State<PurchaseSettingPage> {
  final BuyRequestController controller =
      Get.isRegistered<BuyRequestController>()
      ? Get.find<BuyRequestController>()
      : Get.put(BuyRequestController());
  bool _isSwitchingPurchaseOnline = false;

  @override
  void initState() {
    super.initState();
    controller.refreshPurchaseStatus();
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

  String _purchaseOnlineConfirmKey(bool value) => value
      ? 'app.trade.purchase.message.confirm_online_on'
      : 'app.trade.purchase.message.confirm_online_off';

  String _purchaseOnlineSuccessKey(bool value) => value
      ? 'app.trade.purchase.message.online_on_success'
      : 'app.trade.purchase.message.online_off_success';

  String _purchaseOnlineFailedKey(bool value) => value
      ? 'app.trade.purchase.message.online_on_failed'
      : 'app.trade.purchase.message.online_off_failed';

  Future<void> _handlePurchaseOnlineChanged(bool value) async {
    if (_isSwitchingPurchaseOnline) {
      return;
    }
    final confirmed = await _confirmSwitch(_purchaseOnlineConfirmKey(value));
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _isSwitchingPurchaseOnline = true);
    try {
      final res = await controller.togglePurchaseStatus();
      if (res.success) {
        AppSnackbar.success(_purchaseOnlineSuccessKey(value).tr);
      } else {
        AppSnackbar.error(_purchaseOnlineFailedKey(value).tr);
        await controller.refreshPurchaseStatus();
      }
    } catch (_) {
      AppSnackbar.error(_purchaseOnlineFailedKey(value).tr);
      await controller.refreshPurchaseStatus();
    } finally {
      if (mounted) {
        setState(() => _isSwitchingPurchaseOnline = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onChanged: _isSwitchingPurchaseOnline
                    ? null
                    : _handlePurchaseOnlineChanged,
              ),
            );
          }),
        ],
      ),
    );
  }
}
