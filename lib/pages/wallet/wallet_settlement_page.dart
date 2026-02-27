import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/controllers/wallet/wallet_controller.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/pages/wallet/wallet_settlement_detail_page.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';

class WalletSettlementPage extends StatefulWidget {
  const WalletSettlementPage({super.key});

  @override
  State<WalletSettlementPage> createState() => _WalletSettlementPageState();
}

class _WalletSettlementPageState extends State<WalletSettlementPage> {
  final WalletController controller = Get.isRegistered<WalletController>()
      ? Get.find<WalletController>()
      : Get.put(WalletController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.loadSettlementRecords(reset: true);
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
      controller.loadSettlementRecords();
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
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  WalletSchemaInfo? _findSchema(WalletSettlementDetail detail) {
    final key = detail.marketHashName ?? '';
    if (key.isNotEmpty && controller.settlementSchemas.containsKey(key)) {
      return controller.settlementSchemas[key];
    }
    return null;
  }

  void _openSettlementDetail(WalletSettlementRecord record) {
    Get.to(
      () => WalletSettlementDetailPage(
        record: record,
        schemas: Map<String, WalletSchemaInfo>.from(
          controller.settlementSchemas,
        ),
        users: Map<String, dynamic>.from(controller.settlementUsers),
        stickers: Map<String, dynamic>.from(controller.settlementStickers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    return Scaffold(
      backgroundColor: WalletUi.pageBackground(context),
      appBar: AppBar(title: Text('app.user.wallet.unsettled_details'.tr)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              'app.user.wallet.unsettled_tips'.tr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingSettlement.value &&
                  controller.settlementRecords.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.settlementRecords.isEmpty) {
                return Center(child: Text('app.common.no_data'.tr));
              }
              return RefreshIndicator(
                onRefresh: () => controller.loadSettlementRecords(reset: true),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.settlementRecords.length,
                  itemBuilder: (context, index) {
                    final item = controller.settlementRecords[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: WalletUi.cardShape(context),
                      child: InkWell(
                        borderRadius: WalletUi.cardRadius,
                        onTap: () => _openSettlementDetail(item),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatTime(item.protectionTime),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.protectionTime != null &&
                                      (item.status ?? 0) == 5) ...[
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: CountdownText(
                                        endTimeSeconds: item.protectionTime!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(item, currency),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    WalletSettlementRecord record,
    CurrencyController currency,
  ) {
    final details = record.details;
    if (details.length <= 1) {
      final detail = details.isNotEmpty ? details.first : null;
      final schema = detail == null ? null : _findSchema(detail);
      final imageUrl = schema?.imageUrl ?? detail?.imageUrl ?? '';
      final name =
          schema?.marketName ?? detail?.marketName ?? detail?.marketHashName;
      return Row(
        children: [
          _buildItemImage(imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis),
                if (detail?.paintWear != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${'app.market.csgo.abradability'.tr}: '
                      '${detail?.paintWear?.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            currency.formatUsd(record.price ?? 0),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    }
    final preview = details.take(3).toList();
    return Row(
      children: [
        Expanded(
          child: Row(
            children: preview.map((detail) {
              final schema = _findSchema(detail);
              final imageUrl = schema?.imageUrl ?? detail.imageUrl ?? '';
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildItemImage(imageUrl, size: 48),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (details.length > 3)
              Text(
                '+${details.length - 3}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 6),
            Text(
              currency.formatUsd(record.price ?? 0),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemImage(String url, {double size = 64}) {
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, _) => SizedBox(
          width: size,
          height: size,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, _, __) =>
            const Icon(Icons.image_not_supported_outlined),
      ),
    );
  }
}

class CountdownText extends StatefulWidget {
  const CountdownText({super.key, required this.endTimeSeconds, this.style});

  final int endTimeSeconds;
  final TextStyle? style;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final endTime = DateTime.fromMillisecondsSinceEpoch(
      widget.endTimeSeconds * 1000,
    );
    final diff = endTime.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    if (_remaining == Duration.zero) {
      _timer?.cancel();
    }
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) {
      return '00:00:00';
    }
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = totalSeconds % 60;
    final dayLabel = 'app.common.day'.tr;
    if (days > 0) {
      return '${days.toString().padLeft(2, '0')}$dayLabel '
          '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(_formatDuration(_remaining), style: widget.style);
  }
}
