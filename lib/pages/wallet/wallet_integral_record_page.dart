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
        return RefreshIndicator(
          onRefresh: () => controller.loadIntegralRecords(reset: true),
          child: controller.integralRecords.isEmpty
              ? ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 180),
                    Center(child: Text('app.common.no_data'.tr)),
                  ],
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
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
                    final colorScheme = Theme.of(context).colorScheme;
                    final color = isNegative
                        ? colorScheme.error
                        : const Color(0xFF18A058);
                    final iconBg = color.withValues(alpha: 0.12);
                    final valueText =
                        '${isNegative ? '-' : '+'}${item.value ?? 0}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: WalletUi.cardShape(context),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isNegative
                                        ? Icons.remove_rounded
                                        : Icons.add_rounded,
                                    color: color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.typeName ?? '-',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            valueText,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: color,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(item.createTime),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'app.trade.order.details'.tr,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.id ?? '-',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                        ),
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        'app.user.integral.unit'.tr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${item.changedIntegral ?? 0}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
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
