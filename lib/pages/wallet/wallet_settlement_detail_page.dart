import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class WalletSettlementDetailPage extends StatelessWidget {
  const WalletSettlementDetailPage({
    super.key,
    required this.record,
    required this.schemas,
    required this.users,
    required this.stickers,
  });

  final WalletSettlementRecord record;
  final Map<String, WalletSchemaInfo> schemas;
  final Map<String, dynamic> users;
  final Map<String, dynamic> stickers;

  @override
  Widget build(BuildContext context) {
    final currency = Get.isRegistered<CurrencyController>()
        ? Get.find<CurrencyController>()
        : null;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sellerId = _pickRawValue(record.raw, const ['seller', 'seller_id']);
    final buyerId = _pickRawValue(record.raw, const ['buyer', 'buyer_id']);
    final sellerName = _resolveUserName(sellerId);
    final buyerName = _resolveUserName(buyerId);
    final totalPrice = _sumRecordPrice();
    final isReceivable = (record.status ?? 0) == 4;

    return BackToTopScope(
      enabled: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('app.trade.order.details'.tr),
          actions: [
            IconButton(
              tooltip: 'app.user.menu.feedback'.tr,
              onPressed: () => Get.toNamed(Routers.FEEDBACK_LIST),
              icon: const Icon(Icons.headset_mic_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${'app.trade.type'.tr}: ${_resolveTypeName()}',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _buildStatusText(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: _statusColor(record.status, colorScheme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (sellerName != null && sellerName.isNotEmpty)
                      _InfoRow(
                        label: 'app.market.seller'.tr,
                        value: sellerName,
                      ),
                    if (buyerName != null && buyerName.isNotEmpty)
                      _InfoRow(label: 'app.market.buyer'.tr, value: buyerName),
                    _InfoRow(
                      label: 'app.trade.order.time'.tr,
                      value: _formatTime(
                        _pickRawInt(record.raw, const [
                              'createTime',
                              'create_time',
                              'time',
                            ]) ??
                            record.protectionTime,
                      ),
                    ),
                    _CopyInfoRow(
                      label: 'app.trade.order.number'.tr,
                      value: record.id?.toString() ?? '-',
                      onCopy: record.id == null
                          ? null
                          : () => _copyOrderId(record.id!.toString()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'app.trade.order.total_price'.tr,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatPrice(currency, totalPrice),
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (record.details.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(child: Text('app.common.no_data'.tr)),
                ),
              )
            else
              ...record.details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDetailCard(
                    context: context,
                    detail: detail,
                    currency: currency,
                  ),
                ),
              ),
            _buildTips(context),
          ],
        ),
        bottomNavigationBar: isReceivable
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Get.toNamed(
                        Routers.SHOP_PURCHASE,
                        arguments: {'initialTab': 0},
                      ),
                      child: Text('app.market.product.receive'.tr),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDetailCard({
    required BuildContext context,
    required WalletSettlementDetail detail,
    required CurrencyController? currency,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final schema = _lookupSchema(detail);
    final imageUrl = _resolveImageUrl(detail, schema);
    final title = _resolveTitle(detail, schema);
    final rarity = _schemaTag(schema, 'rarity');
    final quality = _schemaTag(schema, 'quality');
    final paintWearText = _paintWearText(detail);
    final paintWear = _paintWearValue(detail);
    final detailStickers = _detailStickers(detail);
    final count = _detailCount(detail);
    final totalPrice =
        _pickRawDouble(detail.raw, const ['total_price', 'totalPrice']) ??
        (detail.price ?? 0) * count;
    final unitPrice =
        detail.price ?? (count > 0 ? totalPrice / count : totalPrice);
    final wearText = paintWearText ?? paintWear?.toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  height: 58,
                  child: GameItemImage(
                    imageUrl: imageUrl,
                    appId: _resolveDetailAppId(detail, schema),
                    rarity: rarity,
                    quality: quality,
                    count: count > 1 ? count : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatPrice(currency, unitPrice),
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (count > 1)
                            Text(
                              'x$count',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (wearText != null && wearText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${'app.market.csgo.abradability'.tr}: $wearText',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (paintWear != null) ...[
              const SizedBox(height: 6),
              WearProgressBar(paintWear: paintWear),
            ],
            if (detailStickers.isNotEmpty) ...[
              const SizedBox(height: 10),
              StickerRow(stickers: detailStickers, size: 24),
            ],
            if (count > 1) ...[
              const SizedBox(height: 8),
              Text(
                '${'app.trade.order.total_price'.tr}: ${_formatPrice(currency, totalPrice)}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTips(BuildContext context) {
    final tips = [
      'app.trade.order.buyer_tips_1'.tr,
      'app.trade.order.buyer_tips_2'.tr,
      'app.trade.order.buyer_tips_3'.tr,
      'app.trade.order.buyer_tips_4'.tr,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'app.system.tips.warm'.tr,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < tips.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${i + 1}. ${tips[i]}'),
              ),
          ],
        ),
      ),
    );
  }

  WalletSchemaInfo? _lookupSchema(WalletSettlementDetail detail) {
    final hash = detail.marketHashName ?? '';
    if (hash.isNotEmpty && schemas.containsKey(hash)) {
      return schemas[hash];
    }
    final schemaIdKey = detail.schemaId?.toString();
    if (schemaIdKey != null && schemas.containsKey(schemaIdKey)) {
      return schemas[schemaIdKey];
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
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _pickRawInt(dynamic source, List<String> keys) {
    return _asInt(_pickRawValue(source, keys));
  }

  double? _pickRawDouble(dynamic source, List<String> keys) {
    return _asDouble(_pickRawValue(source, keys));
  }

  int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  int _resolveDetailAppId(
    WalletSettlementDetail detail,
    WalletSchemaInfo? schema,
  ) {
    return detail.appId ??
        schema?.appId ??
        _pickRawInt(detail.raw, const ['app_id', 'appId']) ??
        _pickRawInt(schema?.raw, const ['app_id', 'appId']) ??
        GameStorage.getGameType();
  }

  String _resolveTypeName() {
    return _pickRawText(record.raw, const [
          'typeName',
          'type_name',
          'typeNameText',
          'type_name_text',
        ]) ??
        '-';
  }

  String _buildStatusText() {
    final statusName = _pickRawText(record.raw, const [
      'statusName',
      'status_name',
      'statusText',
      'status_text',
    ]);
    if (statusName != null) {
      return statusName;
    }
    if (record.status != null) {
      return record.status.toString();
    }
    return '-';
  }

  Color _statusColor(int? status, ColorScheme colorScheme) {
    if ([4, 5, 6].contains(status)) {
      return const Color(0xFF008000);
    }
    if ([2, 3].contains(status)) {
      return const Color(0xFFC22121);
    }
    return colorScheme.onSurfaceVariant;
  }

  String _resolveImageUrl(
    WalletSettlementDetail detail,
    WalletSchemaInfo? schema,
  ) {
    return detail.imageUrl ??
        schema?.imageUrl ??
        _pickRawText(detail.raw, const ['image_url', 'imageUrl', 'image']) ??
        _pickRawText(schema?.raw, const ['image_url', 'imageUrl', 'image']) ??
        '';
  }

  String _resolveTitle(
    WalletSettlementDetail detail,
    WalletSchemaInfo? schema,
  ) {
    return detail.marketName ??
        schema?.marketName ??
        detail.marketHashName ??
        '-';
  }

  String? _resolveUserName(dynamic userId) {
    if (userId == null) {
      return null;
    }
    final key = userId.toString();
    final direct = _extractUserName(users[key]);
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    for (final entry in users.entries) {
      if (entry.key.toString() == key) {
        final nickname = _extractUserName(entry.value);
        if (nickname != null && nickname.isNotEmpty) {
          return nickname;
        }
      }
    }
    return null;
  }

  String? _extractUserName(dynamic value) {
    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }
    if (value is Map) {
      final nickname =
          value['nickname'] ??
          value['nickName'] ??
          value['name'] ??
          value['userName'] ??
          value['username'];
      if (nickname == null) {
        return null;
      }
      final text = nickname.toString().trim();
      return text.isEmpty ? null : text;
    }
    return null;
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) {
      return '-';
    }
    var normalized = timestamp;
    if (normalized < 10000000000) {
      normalized *= 1000;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(normalized);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  String? _paintWearText(WalletSettlementDetail detail) {
    return _pickRawText(detail.raw, const ['paint_wear', 'paintWear']) ??
        detail.paintWear?.toString();
  }

  double? _paintWearValue(WalletSettlementDetail detail) {
    return detail.paintWear ??
        _pickRawDouble(detail.raw, const ['paint_wear', 'paintWear']);
  }

  List<GameItemSticker> _detailStickers(WalletSettlementDetail detail) {
    final rawAsset = _pickRawValue(detail.raw, const ['asset']);
    final rawCsgoAsset = _pickRawValue(detail.raw, const ['csgoAsset']);
    final stickerRaw =
        _pickRawValue(detail.raw, const ['stickers']) ??
        _pickRawValue(rawAsset, const ['stickers']) ??
        _pickRawValue(rawCsgoAsset, const ['stickers']);
    return parseStickerList(
      stickerRaw,
      schemaMap: schemas,
      stickerMap: stickers,
    );
  }

  int _detailCount(WalletSettlementDetail detail) {
    final count =
        _pickRawInt(detail.raw, const ['count', 'num', 'quantity']) ?? 1;
    return count < 1 ? 1 : count;
  }

  double _sumRecordPrice() {
    if (record.price != null) {
      return record.price!;
    }
    double total = 0;
    for (final detail in record.details) {
      final count = _detailCount(detail);
      final detailTotal =
          _pickRawDouble(detail.raw, const ['total_price', 'totalPrice']) ??
          ((detail.price ?? 0) * count);
      total += detailTotal;
    }
    return total;
  }

  String _formatPrice(CurrencyController? currency, double value) {
    if (currency != null) {
      return currency.formatUsd(value);
    }
    return '\$ ${value.toStringAsFixed(2)}';
  }

  Future<void> _copyOrderId(String orderId) async {
    await Clipboard.setData(ClipboardData(text: orderId));
    AppSnackbar.success('app.system.message.copy_success'.tr);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyInfoRow extends StatelessWidget {
  const _CopyInfoRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onCopy,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 0),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('app.common.copy'.tr),
            ),
          ],
        ],
      ),
    );
  }
}
