import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
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

  String _formatTime(dynamic value) {
    if (value == null) {
      return '-';
    }

    DateTime? dateTime;
    int? timestamp;

    if (value is DateTime) {
      dateTime = value;
    } else if (value is num) {
      timestamp = value.toInt();
    } else {
      final text = value.toString().trim();
      if (text.isEmpty) {
        return '-';
      }
      final numeric = num.tryParse(text);
      if (numeric != null) {
        timestamp = numeric.toInt();
      } else {
        dateTime =
            DateTime.tryParse(text) ??
            DateTime.tryParse(text.replaceAll('/', '-'));
        if (dateTime == null) {
          return '-';
        }
      }
    }

    if (dateTime == null) {
      if (timestamp == null || timestamp <= 0 || timestamp < 1000000000) {
        return '-';
      }
      if (timestamp < 1000000000000) {
        timestamp *= 1000;
      } else if (timestamp >= 1000000000000000) {
        timestamp = (timestamp / 1000).round();
      }
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: WalletUi.pageBackground(context),
      appBar: AppBar(title: Text('app.user.wallet.lock_details'.tr)),
      body: Obx(() {
        if (controller.isLoadingLocked.value &&
            controller.lockedItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadLockedFunds(reset: true),
          child: controller.lockedItems.isEmpty
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
                  itemCount: controller.lockedItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= controller.lockedItems.length) {
                      return _buildLoadMoreFooter(
                        loading: controller.isLoadingLocked.value,
                        hasMore: controller.hasMoreLocked,
                      );
                    }
                    final item = controller.lockedItems[index];
                    final timeCandidates = [
                      item.lockTimeRaw,
                      item.lockAmount,
                      item.createTimeRaw,
                      item.createTime,
                    ];
                    final time = timeCandidates
                        .map(_formatTime)
                        .firstWhere((value) => value != '-', orElse: () => '-');
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
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${'app.user.wallet.lock_amount'.tr}: ',
                                    ),
                                    TextSpan(
                                      text: currency.formatUsd(
                                        item.amount ?? 0,
                                      ),
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${'app.user.wallet.gift_amount'.tr}: ',
                                    ),
                                    TextSpan(
                                      text: currency.formatUsd(
                                        item.giftAmount ?? 0,
                                      ),
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildLoadMoreFooter({required bool loading, required bool hasMore}) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 16),
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
