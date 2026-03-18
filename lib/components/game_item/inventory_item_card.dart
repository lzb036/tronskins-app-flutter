import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/quality_ribbon.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    super.key,
    required this.item,
    this.schema,
    this.schemaMap,
    this.stickerMap,
    this.useSchemaBuffMinPrice = true,
    this.selected = false,
    this.disabledLabel,
    this.onTap,
  });

  final InventoryItem item;
  final ShopSchemaInfo? schema;
  final Map<dynamic, dynamic>? schemaMap;
  final Map<dynamic, dynamic>? stickerMap;
  final bool useSchemaBuffMinPrice;
  final bool selected;
  final String? disabledLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final appId = item.appId;
    final imageUrl = item.imageUrl ?? schema?.imageUrl ?? '';
    final title =
        item.marketName ?? schema?.marketName ?? item.marketHashName ?? '-';
    final tags = schema?.raw['tags'];
    final quality = TagInfo.fromRaw(tags is Map ? tags['quality'] : null);
    final rarity = TagInfo.fromRaw(tags is Map ? tags['rarity'] : null);
    final exterior = TagInfo.fromRaw(tags is Map ? tags['exterior'] : null);
    final asset = _resolveAsset(item);
    final paintWearValue =
        item.paintWear ?? _extractDouble(asset, ['paint_wear', 'paintWear']);
    final paintWearText =
        _extractText(asset, ['paint_wear', 'paintWear']) ??
        _extractText(item.raw, ['paint_wear', 'paintWear']) ??
        _formatWear(paintWearValue);
    final stickerBottomOffset =
        paintWearText != null && paintWearText.isNotEmpty ? 16.0 : 0.0;
    final onSaleBottomOffset = paintWearText != null && paintWearText.isNotEmpty
        ? 14.0
        : 0.0;
    final paintSeed =
        item.paintSeed ?? _extractText(asset, ['paint_seed', 'paintSeed']);
    final phase = item.phase ?? _extractText(asset, ['phase']);
    final percentage = _extractText(asset, ['percentage']);
    final showQualityRibbon = appId != 570 && _shouldShowQualityRibbon(quality);
    final showOnSaleBadge = item.status == 1 || item.status == 2;
    final stickers = parseStickerList(
      asset?['stickers'] ?? item.raw['stickers'],
      schemaMap: schemaMap,
      stickerMap: stickerMap,
    );
    final gems = parseGemList(
      asset?['gemList'] ??
          asset?['gems'] ??
          item.raw['gemList'] ??
          item.raw['gems'],
    );
    final price = _resolveDisplayPrice(
      schema: schema,
      itemPrice: item.price,
      useSchemaBuffMinPrice: useSchemaBuffMinPrice,
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GameItemImage(
                      imageUrl: imageUrl,
                      appId: appId,
                      rarity: rarity,
                      quality: quality,
                      exterior: exterior,
                      cooldown: item.cooldown,
                      paintSeed: paintSeed,
                      phase: phase,
                      percentage: percentage,
                      paintWearText: paintWearText,
                      count: item.count,
                      selected: false,
                      showOnSaleBadge: showOnSaleBadge,
                      disabledLabel: disabledLabel,
                      stickers: stickers,
                      gems: gems,
                      stickerBottomOffset: stickerBottomOffset,
                      onSaleBottomOffset: onSaleBottomOffset,
                    ),
                  ),
                  if (showQualityRibbon && quality != null)
                    Positioned(
                      right: -28,
                      top: 13,
                      child: QualityRibbon(quality: quality),
                    ),
                  if (selected)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Image.asset(
                        'assets/images/game/item/gou.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                ],
              ),
            ),
            if (paintWearValue != null)
              WearProgressBar(paintWear: paintWearValue),
            if (paintWearValue == null && appId == 730)
              const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Row(
                children: [
                  Obx(
                    () => Text(
                      currency.format(price),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (item.tradable == false)
                    Text(
                      'app.trade.non_tradable'.tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _shouldShowQualityRibbon(TagInfo? quality) {
  if (quality == null) {
    return false;
  }
  final name = quality.name?.toLowerCase();
  if (name == 'normal' || name == 'unusual') {
    return false;
  }
  return quality.hasLabel;
}

String? _formatWear(double? wear) {
  if (wear == null) {
    return null;
  }
  return wear.toString();
}

double _parsePriceValue(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double _normalizePrice(double value) {
  if (!value.isFinite || value <= 0) {
    return 0;
  }
  final rounded = double.parse(value.toStringAsFixed(2));
  return rounded;
}

double _resolveDisplayPrice({
  required ShopSchemaInfo? schema,
  required double? itemPrice,
  required bool useSchemaBuffMinPrice,
}) {
  if (!useSchemaBuffMinPrice) {
    final directPrice = _parsePriceValue(itemPrice);
    if (directPrice > 0) {
      return _normalizePrice(directPrice);
    }
    return 0;
  }

  if (schema != null) {
    final raw = schema.raw;
    final buffMinPrice = _parsePriceValue(
      raw['buff_min_price'] ?? raw['buffMinPrice'],
    );
    if (buffMinPrice > 0) {
      return _normalizePrice(buffMinPrice);
    }
  }

  final directPrice = _parsePriceValue(itemPrice);
  if (directPrice > 0) {
    return _normalizePrice(directPrice);
  }
  return 0;
}

Map<String, dynamic>? _resolveAsset(InventoryItem item) {
  final raw = item.raw;
  if (item.appId == 730 && raw['csgoAsset'] is Map<String, dynamic>) {
    return raw['csgoAsset'] as Map<String, dynamic>;
  }
  if (item.appId == 440 && raw['tf2Asset'] is Map<String, dynamic>) {
    return raw['tf2Asset'] as Map<String, dynamic>;
  }
  if (item.appId == 570 && raw['dota2Asset'] is Map<String, dynamic>) {
    return raw['dota2Asset'] as Map<String, dynamic>;
  }
  return raw;
}

String? _extractText(dynamic raw, List<String> keys) {
  if (raw is Map) {
    for (final key in keys) {
      final value = raw[key];
      if (value != null) {
        return value.toString();
      }
    }
  }
  return null;
}

double? _extractDouble(dynamic raw, List<String> keys) {
  if (raw is Map) {
    for (final key in keys) {
      final value = raw[key];
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
  }
  return null;
}
