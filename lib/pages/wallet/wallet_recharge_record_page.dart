import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/controllers/wallet/wallet_controller.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';

class WalletRechargeRecordPage extends StatefulWidget {
  const WalletRechargeRecordPage({super.key});

  @override
  State<WalletRechargeRecordPage> createState() =>
      _WalletRechargeRecordPageState();
}

class _WalletRechargeRecordPageState extends State<WalletRechargeRecordPage> {
  final WalletController controller = Get.isRegistered<WalletController>()
      ? Get.find<WalletController>()
      : Get.put(WalletController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.loadRechargeRecords(reset: true);
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
      controller.loadRechargeRecords();
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
      appBar: AppBar(title: Text('app.user.wallet.recharge_record'.tr)),
      body: Obx(() {
        if (controller.isLoadingRechargeRecords.value &&
            controller.rechargeRecords.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.rechargeRecords.isEmpty) {
          return Center(child: Text('app.common.no_data'.tr));
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadRechargeRecords(reset: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: controller.rechargeRecords.length,
            itemBuilder: (context, index) {
              final item = controller.rechargeRecords[index];
              final statusColor = (item.status ?? 0) == 0
                  ? Theme.of(context).colorScheme.error
                  : Colors.green;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: WalletUi.cardShape(context),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _formatTime(item.createTime),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              item.statusName ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.modeName ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            currency.formatUsd(item.amount ?? 0),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
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
