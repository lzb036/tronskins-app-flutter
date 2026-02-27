import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/controllers/wallet/wallet_controller.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';

class WalletFlowPage extends StatefulWidget {
  const WalletFlowPage({super.key});

  @override
  State<WalletFlowPage> createState() => _WalletFlowPageState();
}

class _WalletFlowPageState extends State<WalletFlowPage> {
  final WalletController controller = Get.isRegistered<WalletController>()
      ? Get.find<WalletController>()
      : Get.put(WalletController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.loadFundFlows(reset: true);
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
      controller.loadFundFlows();
    }
  }

  bool _isPositive(int? type) {
    return type != null && [1, 2, 4, 6, 10].contains(type);
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
      appBar: AppBar(title: Text('app.user.wallet.flow'.tr)),
      body: Obx(() {
        if (controller.isLoadingFundFlows.value &&
            controller.fundFlows.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.fundFlows.isEmpty) {
          return Center(child: Text('app.common.no_data'.tr));
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadFundFlows(reset: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: controller.fundFlows.length + 1,
            itemBuilder: (context, index) {
              if (index >= controller.fundFlows.length) {
                return _buildLoadMoreFooter(
                  context,
                  loading: controller.isLoadingFundFlows.value,
                );
              }
              final item = controller.fundFlows[index];
              final positive = _isPositive(item.type);
              final amountValue = item.amount?.abs() ?? item.amount ?? 0;
              return _buildFlowCard(
                context,
                currency,
                item: item,
                positive: positive,
                amountValue: amountValue,
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildFlowCard(
    BuildContext context,
    CurrencyController currency, {
    required dynamic item,
    required bool positive,
    required double amountValue,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final amountColor = positive ? const Color(0xFF18A058) : colorScheme.error;
    final iconColor = positive
        ? const Color(0xFF18A058)
        : const Color(0xFFD14343);
    final iconBg = iconColor.withValues(alpha: 0.12);
    final amountText = positive
        ? '+ ${currency.formatUsd(amountValue)}'
        : '- ${currency.formatUsd(amountValue)}';

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
                    positive
                        ? Icons.call_received_rounded
                        : Icons.call_made_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.typeName ?? '-',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            amountText,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: amountColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(item.createTime),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    label: 'app.trade.order.number'.tr,
                    value: item.serialNumber?.toString() ?? '-',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    label: 'app.user.wallet.balance'.tr,
                    value: currency.formatUsd(item.beforeBalance ?? 0),
                    valueColor: colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: valueColor,
    );
    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMoreFooter(BuildContext context, {required bool loading}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: loading
          ? const Padding(
              key: ValueKey('flow_loading'),
              padding: EdgeInsets.fromLTRB(0, 4, 0, 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            )
          : const SizedBox(key: ValueKey('flow_idle'), height: 4),
    );
  }
}
