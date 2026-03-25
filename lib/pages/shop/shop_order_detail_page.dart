import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/common/utils/app_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/widgets/back_to_top_overlay.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class ShopOrderDetailPage extends StatelessWidget {
  const ShopOrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = _ShopOrderDetailArgs.fromDynamic(Get.arguments);
    final order = args.order;
    if (order == null) {
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
          body: Center(child: Text('app.common.no_data'.tr)),
        ),
      );
    }
    final currency = Get.isRegistered<CurrencyController>()
        ? Get.find<CurrencyController>()
        : null;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sellerId = order.raw['seller'] ?? order.raw['seller_id'];
    final buyerId =
        order.raw['buyer'] ?? order.raw['buyer_id'] ?? order.buyerId;
    final sellerName = _resolveUserName(
      users: args.users,
      userId: sellerId,
      fallback: order.user?.nickname,
    );
    final buyerName = _resolveUserName(users: args.users, userId: buyerId);
    final totalPrice = _sumOrderPrice(order);

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
                        '${'app.trade.type'.tr}: ${_resolveTypeName(order)}',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _buildStatusText(order),
                      style: textTheme.bodyMedium?.copyWith(
                        color: _statusColor(order.status, colorScheme),
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
                      value: _formatTime(order.createTime),
                    ),
                    _CopyInfoRow(
                      label: 'app.trade.order.number'.tr,
                      value: order.id?.toString() ?? '-',
                      onCopy: order.id == null
                          ? null
                          : () => _copyOrderId(order.id!.toString()),
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
            if (order.details.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(child: Text('app.common.no_data'.tr)),
                ),
              )
            else
              ...order.details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDetailCard(
                    context: context,
                    detail: detail,
                    schemas: args.schemas,
                    stickers: args.stickers,
                    currency: currency,
                  ),
                ),
              ),
            _buildTips(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required BuildContext context,
    required ShopOrderDetail detail,
    required Map<String, ShopSchemaInfo> schemas,
    required Map<String, dynamic> stickers,
    required CurrencyController? currency,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final schema = _lookupSchema(
      schemas: schemas,
      marketHashName: detail.marketHashName,
      schemaId: detail.schemaId,
    );
    final appId = _resolveDetailAppId(detail, schema);
    final imageUrl = detail.imageUrl ?? schema?.imageUrl ?? '';
    final title = detail.marketName ?? schema?.marketName ?? '-';
    final rarity = _schemaTag(schema, 'rarity');
    final quality = _schemaTag(schema, 'quality');
    final paintWearText = _detailText(detail, ['paint_wear', 'paintWear']);
    final paintWear =
        detail.paintWear ?? _detailDouble(detail, ['paint_wear', 'paintWear']);
    final rawAsset = detail.raw['asset'];
    final rawCsgoAsset = detail.raw['csgoAsset'];
    final stickerRaw =
        detail.raw['stickers'] ??
        (rawAsset is Map ? rawAsset['stickers'] : null) ??
        (rawCsgoAsset is Map ? rawCsgoAsset['stickers'] : null);
    final detailStickers = parseStickerList(
      stickerRaw,
      schemaMap: schemas,
      stickerMap: stickers,
    );
    final count = detail.count ?? 1;
    final unitPrice =
        detail.price ??
        ((detail.totalPrice != null && count > 0)
            ? detail.totalPrice! / count
            : 0.0);
    final totalPrice = detail.totalPrice ?? unitPrice * count;
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
                    appId: appId,
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

  ShopSchemaInfo? _lookupSchema({
    required Map<String, ShopSchemaInfo> schemas,
    required String? marketHashName,
    required int? schemaId,
  }) {
    if (marketHashName != null && schemas.containsKey(marketHashName)) {
      return schemas[marketHashName];
    }
    final key = schemaId?.toString();
    if (key != null && schemas.containsKey(key)) {
      return schemas[key];
    }
    return null;
  }

  TagInfo? _schemaTag(ShopSchemaInfo? schema, String key) {
    final tags = schema?.raw['tags'];
    if (tags is Map) {
      return TagInfo.fromRaw(tags[key]);
    }
    return null;
  }

  int _resolveDetailAppId(ShopOrderDetail detail, ShopSchemaInfo? schema) {
    final raw = detail.raw;
    final schemaRaw = schema?.raw;
    final rawApp = raw['app_id'] ?? raw['appId'];
    final schemaApp = schemaRaw?['app_id'] ?? schemaRaw?['appId'];
    return _asInt(rawApp) ?? _asInt(schemaApp) ?? GameStorage.getGameType();
  }

  String? _detailText(ShopOrderDetail detail, List<String> keys) {
    for (final key in keys) {
      final value = detail.raw[key];
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  double? _detailDouble(ShopOrderDetail detail, List<String> keys) {
    for (final key in keys) {
      final value = detail.raw[key];
      if (value == null) {
        continue;
      }
      if (value is num) {
        return value.toDouble();
      }
      final parsed = double.tryParse(value.toString());
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
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

  String _buildStatusText(ShopOrderItem order) {
    final status = order.status;
    if (status == 6) {
      return 'app.trade.sale.success'.tr;
    }
    final statusName = order.statusName?.trim();
    if ([2, 3, 4].contains(status)) {
      return (statusName == null || statusName.isEmpty) ? '-' : statusName;
    }
    final cancelDesc = order.cancelDesc?.trim();
    if (![2, 3, 4, 5, 6].contains(status) &&
        cancelDesc != null &&
        cancelDesc.isNotEmpty) {
      return cancelDesc;
    }
    if (statusName != null && statusName.isNotEmpty) {
      return statusName;
    }
    return '-';
  }

  Color _statusColor(int? status, ColorScheme colorScheme) {
    if ([5, 6].contains(status)) {
      return const Color(0xFF008000);
    }
    if ([2, 3, 4].contains(status)) {
      return const Color(0xFFC22121);
    }
    return colorScheme.onSurfaceVariant;
  }

  String _resolveTypeName(ShopOrderItem order) {
    final typeName =
        order.raw['typeName']?.toString() ??
        order.raw['type_name']?.toString() ??
        order.raw['typeNameText']?.toString() ??
        order.raw['type_name_text']?.toString();
    if (typeName != null && typeName.isNotEmpty) {
      return typeName;
    }
    return order.type?.toString() ?? '-';
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) {
      return '-';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  double _sumOrderPrice(ShopOrderItem order) {
    if (order.price != null) {
      return order.price!;
    }
    double total = 0;
    for (final detail in order.details) {
      final unit = detail.price ?? 0;
      final count = detail.count ?? 1;
      total += unit * count;
    }
    return total;
  }

  String _formatPrice(CurrencyController? currency, double value) {
    if (currency != null) {
      return currency.format(value);
    }
    return value.toStringAsFixed(2);
  }

  String? _resolveUserName({
    required Map<String, ShopUserInfo> users,
    required dynamic userId,
    String? fallback,
  }) {
    if (userId != null) {
      final key = userId.toString();
      final user = users[key];
      if (user != null && (user.nickname ?? '').isNotEmpty) {
        return user.nickname;
      }
      for (final entry in users.entries) {
        if (entry.key.toString() == key) {
          final nickname = entry.value.nickname;
          if (nickname != null && nickname.isNotEmpty) {
            return nickname;
          }
        }
      }
    }
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }
    return null;
  }

  Future<void> _copyOrderId(String orderId) async {
    await Clipboard.setData(ClipboardData(text: orderId));
    AppSnackbar.success('app.system.message.copy_success'.tr);
  }
}

class _ShopOrderDetailArgs {
  const _ShopOrderDetailArgs({
    this.order,
    this.schemas = const {},
    this.users = const {},
    this.stickers = const {},
  });

  final ShopOrderItem? order;
  final Map<String, ShopSchemaInfo> schemas;
  final Map<String, ShopUserInfo> users;
  final Map<String, dynamic> stickers;

  factory _ShopOrderDetailArgs.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const _ShopOrderDetailArgs();
    }
    final order = _parseOrder(raw['order'] ?? raw['item']);
    return _ShopOrderDetailArgs(
      order: order,
      schemas: _parseSchemas(raw['schemas']),
      users: _parseUsers(raw['users']),
      stickers: _parseStickers(raw['stickers']),
    );
  }

  static ShopOrderItem? _parseOrder(dynamic value) {
    if (value is ShopOrderItem) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      return ShopOrderItem.fromJson(value);
    }
    if (value is Map) {
      final json = <String, dynamic>{};
      value.forEach((key, val) {
        json[key.toString()] = val;
      });
      return ShopOrderItem.fromJson(json);
    }
    return null;
  }

  static Map<String, ShopSchemaInfo> _parseSchemas(dynamic value) {
    final result = <String, ShopSchemaInfo>{};
    if (value is! Map) {
      return result;
    }
    value.forEach((key, val) {
      if (val is ShopSchemaInfo) {
        result[key.toString()] = val;
      } else if (val is Map<String, dynamic>) {
        result[key.toString()] = ShopSchemaInfo.fromJson(val);
      } else if (val is Map) {
        final json = <String, dynamic>{};
        val.forEach((innerKey, innerValue) {
          json[innerKey.toString()] = innerValue;
        });
        result[key.toString()] = ShopSchemaInfo.fromJson(json);
      }
    });
    return result;
  }

  static Map<String, ShopUserInfo> _parseUsers(dynamic value) {
    final result = <String, ShopUserInfo>{};
    if (value is! Map) {
      return result;
    }
    value.forEach((key, val) {
      if (val is ShopUserInfo) {
        result[key.toString()] = val;
      } else if (val is Map<String, dynamic>) {
        result[key.toString()] = ShopUserInfo.fromJson(val);
      } else if (val is Map) {
        final json = <String, dynamic>{};
        val.forEach((innerKey, innerValue) {
          json[innerKey.toString()] = innerValue;
        });
        result[key.toString()] = ShopUserInfo.fromJson(json);
      }
    });
    return result;
  }

  static Map<String, dynamic> _parseStickers(dynamic value) {
    final result = <String, dynamic>{};
    if (value is! Map) {
      return result;
    }
    value.forEach((key, val) {
      result[key.toString()] = val;
    });
    return result;
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
