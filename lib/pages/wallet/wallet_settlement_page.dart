import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/components/layout/list_end_tip.dart';
import 'package:tronskins_app/controllers/wallet/wallet_controller.dart';
import 'package:tronskins_app/pages/wallet/wallet_settlement_detail_page.dart';
import 'package:tronskins_app/pages/wallet/widgets/wallet_ui.dart';

class WalletSettlementPage extends StatefulWidget {
  const WalletSettlementPage({super.key});

  @override
  State<WalletSettlementPage> createState() => _WalletSettlementPageState();
}

class _WalletSettlementPageState extends State<WalletSettlementPage> {
  static const Color _countdownAccent = Color(0xFFFF9800);
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
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 200) {
      controller.loadSettlementRecords();
    }
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
    final marketHashName = detail.marketHashName ?? '';
    if (marketHashName.isNotEmpty &&
        controller.settlementSchemas.containsKey(marketHashName)) {
      return controller.settlementSchemas[marketHashName];
    }
    final schemaIdKey = detail.schemaId?.toString();
    if (schemaIdKey != null &&
        controller.settlementSchemas.containsKey(schemaIdKey)) {
      return controller.settlementSchemas[schemaIdKey];
    }
    return null;
  }

  TagInfo? _schemaTag(WalletSchemaInfo? schema, String key) {
    final tags = schema?.raw['tags'];
    if (tags is Map) {
      return TagInfo.fromRaw(tags[key]);
    }
    return null;
  }

  dynamic _pickRawValue(dynamic source, List<String> keys) {
    if (source is! Map) {
      return null;
    }
    for (final key in keys) {
      final value = source[key];
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  String? _pickRawText(dynamic source, List<String> keys) {
    final value = _pickRawValue(source, keys);
    return value?.toString();
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  int _resolveAppId(WalletSettlementDetail detail, WalletSchemaInfo? schema) {
    return detail.appId ??
        schema?.appId ??
        _asInt(_pickRawValue(detail.raw, const ['app_id', 'appId'])) ??
        _asInt(_pickRawValue(schema?.raw, const ['app_id', 'appId'])) ??
        GameStorage.getGameType();
  }

  String _resolveImageUrl(
    WalletSettlementDetail detail,
    WalletSchemaInfo? schema,
  ) {
    return schema?.imageUrl ??
        detail.imageUrl ??
        _pickRawText(detail.raw, const ['image_url', 'imageUrl', 'image']) ??
        _pickRawText(schema?.raw, const ['image_url', 'imageUrl', 'image']) ??
        '';
  }

  String _resolveTitle(
    WalletSettlementDetail detail,
    WalletSchemaInfo? schema,
  ) {
    return schema?.marketName ??
        detail.marketName ??
        detail.marketHashName ??
        '-';
  }

  String? _paintWearText(WalletSettlementDetail detail) {
    final value = detail.raw['paint_wear'] ?? detail.raw['paintWear'];
    if (value != null) {
      return value.toString();
    }
    return detail.paintWear?.toString();
  }

  double? _paintWearValue(WalletSettlementDetail detail) {
    return detail.paintWear ??
        _asDouble(_pickRawValue(detail.raw, const ['paint_wear', 'paintWear']));
  }

  String? _phaseText(WalletSettlementDetail detail, WalletSchemaInfo? schema) {
    return _pickRawText(detail.raw, const ['phase']) ??
        _pickRawText(schema?.raw, const ['phase']);
  }

  String? _percentageText(
    WalletSettlementDetail detail,
    WalletSchemaInfo? schema,
  ) {
    return _pickRawText(detail.raw, const ['percentage']) ??
        _pickRawText(schema?.raw, const ['percentage']);
  }

  List<GameItemSticker> _detailStickers(WalletSettlementDetail detail) {
    final stickerRaw = _pickRawValue(detail.raw, const ['stickers']);
    return parseStickerList(
      stickerRaw,
      stickerMap: controller.settlementStickers,
    );
  }

  Widget _buildPreviewImage(
    WalletSettlementDetail detail, {
    WalletSchemaInfo? schema,
    double width = 94,
    double height = 58,
    bool showTopBadges = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.34,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: GameItemImage(
          imageUrl: _resolveImageUrl(detail, schema),
          appId: _resolveAppId(detail, schema),
          rarity: _schemaTag(schema, 'rarity'),
          quality: _schemaTag(schema, 'quality'),
          exterior: _schemaTag(schema, 'exterior'),
          phase: _phaseText(detail, schema),
          percentage: _percentageText(detail, schema),
          stickers: _detailStickers(detail),
          avoidTopLeftBadgeOverlap: true,
          compactTopLeftBadges: true,
          showTopBadges: showTopBadges,
        ),
      ),
    );
  }

  Widget _buildRecordCard(
    WalletSettlementRecord record,
    CurrencyController currency,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: WalletUi.cardShape(context),
      child: InkWell(
        borderRadius: WalletUi.cardRadius,
        onTap: () => _openSettlementDetail(record),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatTime(record.protectionTime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (record.protectionTime != null &&
                      (record.status ?? 0) == 5) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: CountdownText(
                          endTimeSeconds: record.protectionTime!,
                          textAlign: TextAlign.end,
                          style: textTheme.bodySmall?.copyWith(
                            color: _countdownAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (record.details.length <= 1)
                _buildSingleDetailSummary(record, currency)
              else
                _buildMultipleDetailSummary(record, currency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleDetailSummary(
    WalletSettlementRecord record,
    CurrencyController currency,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final detail = record.details.isNotEmpty ? record.details.first : null;
    if (detail == null) {
      return Text(
        currency.formatUsd(record.price ?? 0),
        style: textTheme.titleSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final schema = _findSchema(detail);
    final wearText = _paintWearText(detail);
    final wearValue = _paintWearValue(detail);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreviewImage(detail, schema: schema),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _resolveTitle(detail, schema),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    currency.formatUsd(record.price ?? 0),
                    textAlign: TextAlign.end,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (wearText != null && wearText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${'app.market.csgo.abradability'.tr}: $wearText',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (wearValue != null) ...[
                const SizedBox(height: 8),
                WearProgressBar(paintWear: wearValue, height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultipleDetailSummary(
    WalletSettlementRecord record,
    CurrencyController currency,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final previewDetails = record.details.take(2).toList();
    final extraCount = record.details.length - previewDetails.length;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: previewDetails.map((detail) {
              final schema = _findSchema(detail);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildPreviewImage(
                  detail,
                  schema: schema,
                  showTopBadges: false,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (extraCount > 0)
              Text(
                '+$extraCount',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (extraCount > 0) const SizedBox(height: 6),
            Text(
              currency.formatUsd(record.price ?? 0),
              style: textTheme.titleSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return BackToTopScope(
      enabled: true,
      child: Scaffold(
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
                final loading = controller.isLoadingSettlement.value;
                final records = controller.settlementRecords;
                final currency = Get.find<CurrencyController>();

                if (loading && records.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      controller.loadSettlementRecords(reset: true),
                  child: records.isEmpty
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
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                          itemCount: records.length + 1,
                          itemBuilder: (context, index) {
                            if (index >= records.length) {
                              return _buildLoadMoreFooter(
                                loading: loading,
                                hasMore: controller.hasMoreSettlementRecords,
                              );
                            }
                            return _buildRecordCard(records[index], currency);
                          },
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class CountdownText extends StatefulWidget {
  const CountdownText({
    super.key,
    required this.endTimeSeconds,
    this.style,
    this.textAlign,
  });

  final int endTimeSeconds;
  final TextStyle? style;
  final TextAlign? textAlign;

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
    return Text(
      _formatDuration(_remaining),
      textAlign: widget.textAlign,
      style: widget.style,
    );
  }
}
