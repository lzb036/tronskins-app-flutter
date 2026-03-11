import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/controllers/wallet/integral_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class IntegralPage extends StatefulWidget {
  const IntegralPage({super.key});

  @override
  State<IntegralPage> createState() => _IntegralPageState();
}

class _IntegralPageState extends State<IntegralPage> {
  final IntegralController controller = Get.isRegistered<IntegralController>()
      ? Get.find<IntegralController>()
      : Get.put(IntegralController());

  @override
  void initState() {
    super.initState();
    controller.refreshUser();
    controller.loadCouponsList();
  }

  Future<void> _exchange(int type) async {
    final ok = await controller.exchangeCoupon(type);
    if (ok) {
      Get.snackbar('app.system.tips.title'.tr, 'app.system.message.success'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.user.integral.title'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.toNamed(Routers.WALLET_INTEGRAL_RECORD),
            child: Text('app.user.wallet.integral_details'.tr),
          ),
        ],
      ),
      body: Obx(() {
        final integral = controller.integralValue;
        final coupons = controller.couponItems;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '$integral',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'app.user.integral.unit'.tr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: Text('app.user.integral.draw'.tr),
                subtitle: Text('app.user.integral.draw_weekly'.tr),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed(Routers.INTEGRAL_DRAW),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'app.user.equity.card'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (controller.isLoadingCoupons.value)
              const Center(child: CircularProgressIndicator())
            else if (coupons.isEmpty)
              Center(child: Text('app.common.no_data'.tr))
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: coupons.map((item) {
                  final bg = item.couponsType == 1
                      ? const Color(0xFFFB8402)
                      : item.couponsType == 2
                      ? const Color(0xFF752D17)
                      : Theme.of(context).colorScheme.primaryContainer;
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 48) / 2,
                    child: Card(
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            color: bg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.desc ?? item.typeName ?? '-',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${item.value ?? 0}${'app.user.integral.unit'.tr}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.validate != null)
                                  Text(
                                    '${'app.user.coupon.validity'.tr}: '
                                    '${item.validate}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: item.type == null
                                        ? null
                                        : () => _exchange(item.type!),
                                    child: Text('app.user.coupon.exchange'.tr),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      }),
    );
  }
}
