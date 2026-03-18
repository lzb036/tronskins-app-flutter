import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';
import 'package:tronskins_app/components/game_item/game_item_image.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/quality_ribbon.dart';
import 'package:tronskins_app/components/game_item/wear_progress_bar.dart';

class MarketItemCard extends StatelessWidget {
  const MarketItemCard({super.key, required this.item, this.onTap});

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
    final hasWearProgress = paintWearValue != null;
    final showQualityRibbon = !isDota && _shouldShowQualityRibbon(quality);
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
                      right: -28,
                      top: 13,
                      child: QualityRibbon(quality: quality),
                    ),
                ],
              ),
            ),
            if (reserveWearSlot)
              SizedBox(
                height: hasWearProgress ? 14 : 4,
                child: hasWearProgress
                    ? WearProgressBar(paintWear: paintWearValue, height: 14)
                    : const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
              child: Text(
                item.marketName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
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
