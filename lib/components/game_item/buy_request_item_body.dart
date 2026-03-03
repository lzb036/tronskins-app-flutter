import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';

class BuyRequestItemBody extends StatelessWidget {
  const BuyRequestItemBody({
    super.key,
    required this.item,
    this.schema,
    this.trailing,
    this.showPriceLabel = true,
  });

  final BuyRequestItem item;
  final ShopSchemaInfo? schema;
  final Widget? trailing;
  final bool showPriceLabel;

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final appId = item.appId;
    final title =
        schema?.marketName ??
        schema?.marketHashName ??
        item.raw['market_name']?.toString() ??
        '-';
    final imageUrl = schema?.imageUrl ?? '';
    final tags = schema?.raw['tags'];
    final rarity = TagInfo.fromRaw(tags is Map ? tags['rarity'] : null);
    final quality = TagInfo.fromRaw(tags is Map ? tags['quality'] : null);
    final exterior = TagInfo.fromRaw(tags is Map ? tags['exterior'] : null);
    final wearMin =
        _rawText(item.raw, const ['paint_wear_min', 'paintWearMin']) ??
        item.paintWearMin?.toString();
    final wearMax =
        _rawText(item.raw, const ['paint_wear_max', 'paintWearMax']) ??
        item.paintWearMax?.toString();
    final phase = item.phase;
    const imageWidth = 72.0;
    const imageHeight = imageWidth * 0.6;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: imageWidth,
          height: imageHeight,
          child: GameItemImage(
            imageUrl: imageUrl,
            appId: appId,
            rarity: rarity,
            quality: quality,
            exterior: exterior,
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
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (wearMin != null && wearMax != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${'app.market.csgo.wear'.tr}: $wearMin - $wearMax',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (phase != null && phase.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${'app.market.csgo.phase'.tr}: $phase',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (showPriceLabel)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        'app.market.price_unit'.tr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  Obx(
                    () => Text(
                      currency.format(item.price ?? 0),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }

  String? _rawText(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }
}
