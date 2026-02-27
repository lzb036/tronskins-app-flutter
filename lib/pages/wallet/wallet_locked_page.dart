import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/controllers/wallet/wallet_controller.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class WalletLockedPage extends StatefulWidget {
  const WalletLockedPage({super.key});

  @override
  State<WalletLockedPage> createState() => _WalletLockedPageState();
}

class _WalletLockedPageState extends State<WalletLockedPage> {
  final WalletController controller = Get.isRegistered<WalletController>()
      ? Get.find<WalletController>()
      : Get.put(WalletController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.loadLockedFunds(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      controller.loadLockedFunds();
    }
  }

  String _formatTime(int? value) {
    if (value == null) {
      return '-';
    }
    var timestamp = value;
    if (timestamp < 10000000000) {
      timestamp *= 1000;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    return Scaffold(
      backgroundColor: WalletUi.pageBackground(context),
      appBar: AppBar(title: Text('app.user.wallet.lock_details'.tr)),
      body: Obx(() {
        if (controller.isLoadingLocked.value &&
            controller.lockedItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.lockedItems.isEmpty) {
          return Center(child: Text('app.common.no_data'.tr));
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadLockedFunds(reset: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: controller.lockedItems.length,
            itemBuilder: (context, index) {
              final item = controller.lockedItems[index];
              final time = _formatTime(item.lockAmount ?? item.createTime);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: WalletUi.cardShape(context),
                child: ListTile(
                  title: Text(time),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'app.user.wallet.lock_amount'.tr}: '
                          '${currency.formatUsd(item.amount ?? 0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'app.user.wallet.gift'.tr}: '
                          '${currency.formatUsd(item.giftAmount ?? 0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: item.id == null
                      ? null
                      : () => Get.toNamed(
                          Routers.WALLET_LOCKED_DETAIL,
                          arguments: {
                            'id': item.id.toString(),
                            'lockType': item.lockType,
                          },
                        ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
