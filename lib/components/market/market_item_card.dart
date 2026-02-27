import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/quality_ribbon.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';

class MarketItemCard extends StatelessWidget {
  const MarketItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final MarketItemEntity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<CurrencyController>();
    final theme = Theme.of(context);
    final price = item.marketPrice ?? 0;
    final rarity = TagInfo.fromMarketTag(item.tags?.rarity);
    final quality = TagInfo.fromMarketTag(item.tags?.quality);
    final exterior = TagInfo.fromMarketTag(item.tags?.exterior);
    final isDota = item.appId == 570;
    final paintWearText = item.paintWear;
    final paintWearValue = double.tryParse(item.paintWear ?? '');
    final reserveWearSlot = item.appId == 730;
    final nameStyle = theme.textTheme.bodyMedium;
    final nameFontSize = nameStyle?.fontSize ?? 14;
    final nameLineHeight = (nameStyle?.height ?? 1.2) * nameFontSize;
    final nameBoxHeight = nameLineHeight * 2;
    final showQualityRibbon =
        !isDota && _shouldShowQualityRibbon(quality);
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
                      imageUrl: item.imageUrl,
                      appId: item.appId,
                      rarity: rarity,
                      quality: quality,
                      exterior: exterior,
                      cooldown: item.cd,
                      paintSeed: item.paintSeed,
                      phase: item.phase,
                      percentage: item.percentage,
                      paintWearText: paintWearText,
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
            if (reserveWearSlot)
              SizedBox(
                height: 14,
                child: paintWearValue != null
                    ? WearProgressBar(
                        paintWear: paintWearValue,
                        height: 14,
                      )
                    : const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: SizedBox(
                height: nameBoxHeight,
                child: Text(
                  item.marketName ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: nameStyle,
                  strutStyle: StrutStyle(
                    fontSize: nameFontSize,
                    height: nameStyle?.height ?? 1.2,
                    forceStrutHeight: true,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Obx(
                    () => Text(
                      currency.format(price),
                      style: theme.textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${item.sellNum ?? 0} ${'app.trade.onSale.nums'.tr}',
                    style: Theme.of(context).textTheme.bodySmall,
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
