import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/wallet/wallet_controller.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';

class WalletIntegralRecordPage extends StatefulWidget {
  const WalletIntegralRecordPage({super.key});

  @override
  State<WalletIntegralRecordPage> createState() =>
      _WalletIntegralRecordPageState();
}

class _WalletIntegralRecordPageState extends State<WalletIntegralRecordPage> {
  final WalletController controller = Get.isRegistered<WalletController>()
      ? Get.find<WalletController>()
      : Get.put(WalletController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.loadIntegralRecords(reset: true);
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
      controller.loadIntegralRecords();
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
    return Scaffold(
      backgroundColor: WalletUi.pageBackground(context),
      appBar: AppBar(title: Text('app.user.wallet.integral_details'.tr)),
      body: Obx(() {
        if (controller.isLoadingIntegralRecords.value &&
            controller.integralRecords.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.integralRecords.isEmpty) {
          return Center(child: Text('app.common.no_data'.tr));
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadIntegralRecords(reset: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: controller.integralRecords.length + 1,
            itemBuilder: (context, index) {
              if (index >= controller.integralRecords.length) {
                return _buildLoadMoreFooter(
                  loading: controller.isLoadingIntegralRecords.value,
                  hasMore: controller.hasMoreIntegralRecords,
                );
              }
              final item = controller.integralRecords[index];
              final isNegative = item.type == 3;
              final color = isNegative
                  ? Theme.of(context).colorScheme.error
                  : Colors.green;
              final valueText = '${isNegative ? '-' : '+'}${item.value ?? 0}';
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
                              '${'app.trade.order.details'.tr}: ${item.id ?? '-'}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _formatTime(item.createTime),
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                              item.typeName ?? '-',
                              style: TextStyle(color: color),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            valueText,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${item.changedIntegral ?? 0}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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

  Widget _buildLoadMoreFooter({required bool loading, required bool hasMore}) {
    if (loading && hasMore) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    if (!hasMore) {
      return const ListEndTip(padding: EdgeInsets.fromLTRB(8, 6, 8, 12));
    }
    return const SizedBox(height: 4);
  }
}
