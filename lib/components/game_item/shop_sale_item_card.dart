import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/quality_ribbon.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';

class ShopSaleItemCard extends StatelessWidget {
  const ShopSaleItemCard({
    super.key,
    required this.item,
    this.schema,
    this.schemaMap,
    this.stickerMap,
    this.selected = false,
    this.onTap,
  });

  final ShopItemAsset item;
  final ShopSchemaInfo? schema;
  final Map<dynamic, dynamic>? schemaMap;
  final Map<dynamic, dynamic>? stickerMap;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final appId = item.appId;
    final asset = item.asset ?? item.raw['asset'];
    final imageUrl = item.imageUrl ?? schema?.imageUrl ?? '';
    final title =
        item.marketName ?? schema?.marketName ?? item.marketHashName ?? '-';
    final tags = schema?.raw['tags'];
    final quality = TagInfo.fromRaw(tags is Map ? tags['quality'] : null);
    final rarity = TagInfo.fromRaw(tags is Map ? tags['rarity'] : null);
    final exterior = TagInfo.fromRaw(tags is Map ? tags['exterior'] : null);
    final paintWearText = _extractText(asset, ['paint_wear', 'paintWear']);
    final paintWearValue = _extractDouble(asset, ['paint_wear', 'paintWear']);
    final paintSeed = _extractText(asset, ['paint_seed', 'paintSeed']);
    final phase = _extractText(asset, ['phase']);
    final percentage = _extractText(asset, ['percentage']);
    final cooldown = _extractText(asset, ['cd']);
    final stickers = parseStickerList(
      _extractRaw(asset, 'stickers') ?? item.raw['stickers'],
      schemaMap: schemaMap,
      stickerMap: stickerMap,
    );
    final gems = parseGemList(
      _extractRaw(asset, 'gemList') ??
          _extractRaw(asset, 'gems') ??
          item.raw['gemList'] ??
          item.raw['gems'],
    );
    final showQualityRibbon = appId != 570 && _shouldShowQualityRibbon(quality);

    return Card(
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
                      cooldown: cooldown,
                      paintSeed: paintSeed,
                      phase: phase,
                      percentage: percentage,
                      paintWearText: paintWearText,
                      count: item.count,
                      selected: selected,
                      stickers: stickers,
                      gems: gems,
                    ),
                  ),
                  if (showQualityRibbon && quality != null)
                    Positioned(
                      right: -32,
                      top: 12,
                      child: QualityRibbon(quality: quality),
                    ),
                ],
              ),
            ),
            if (paintWearValue != null)
              WearProgressBar(paintWear: paintWearValue),
            if (paintWearValue == null && appId == 730)
              const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Obx(
                () => Text(
                  currency.format(item.price ?? 0),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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

dynamic _extractRaw(dynamic raw, String key) {
  if (raw is Map && raw.containsKey(key)) {
    return raw[key];
  }
  return null;
}
