import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/game_item_utils.dart';
import 'package:tronskins_app/components/game_item/gem_row.dart';
import 'package:tronskins_app/components/game_item/sticker_row.dart';

class GameItemImage extends StatelessWidget {
  const GameItemImage({
    super.key,
    required this.imageUrl,
    required this.appId,
    this.rarity,
    this.quality,
    this.exterior,
    this.cooldown,
    this.paintSeed,
    this.phase,
    this.percentage,
    this.paintWearText,
    this.count,
    this.selected = false,
    this.showOnSaleBadge = false,
    this.disabledLabel,
    this.stickers = const [],
    this.gems = const [],
    this.stickerBottomOffset = 0,
    this.onSaleBottomOffset = 0,
  });

  final String? imageUrl;
  final int? appId;
  final TagInfo? rarity;
  final TagInfo? quality;
  final TagInfo? exterior;
  final String? cooldown;
  final String? paintSeed;
  final String? phase;
  final String? percentage;
  final String? paintWearText;
  final int? count;
  final bool selected;
  final bool showOnSaleBadge;
  final String? disabledLabel;
  final List<GameItemSticker> stickers;
  final List<GameItemGem> gems;
  final double stickerBottomOffset;
  final double onSaleBottomOffset;

  bool get _isDota => appId == 570;

  @override
  Widget build(BuildContext context) {
    final bgAsset = _isDota ? null : rarityBgAsset(rarity?.color);
    final qualityBorder = qualityBorderColor(quality?.color);
    final exteriorColor = parseHexColor(exterior?.color) ?? Colors.black54;
    final badges = _buildBadges(context, exteriorColor);
    final hasCountBadge = count != null && count! > 1;
    final stickerBottom =
        (_isDota ? 3.0 : (hasCountBadge ? 20.0 : 2.0)) + stickerBottomOffset;
    final stickerLeft = _isDota ? 0.0 : 6.0;
    final stickerSize = _isDota ? 15.0 : 16.0;
    final gemLeft = _isDota ? 10.0 : 6.0;
    final gemBottom = _isDota ? 15.0 : 10.0;
    final gemSize = _isDota ? 15.0 : 16.0;
    final stickerBottomWithGem = gems.isNotEmpty
        ? stickerBottom + gemSize + 4.0
        : stickerBottom;
    final countBottom = _isDota && stickers.isNotEmpty ? 24.0 : 6.0;
    final onSaleBottom =
        (hasCountBadge ? countBottom + 18.0 : 6.0) + onSaleBottomOffset;
    final badgeLeft = _isDota ? 4.0 : 6.0;
    final badgeTop = 4.0;
    final badgeMaxWidth = _isDota ? 130.0 : 145.0;
    return Stack(
      children: [
        if (bgAsset != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.95,
              child: Image.asset(
                bgAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Image.asset(
                  'assets/images/game/item/b0c3d9.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final image = CachedNetworkImage(
                imageUrl: imageUrl ?? '',
                fit: BoxFit.contain,
                placeholder: (context, _) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, _, __) =>
                    const Icon(Icons.image_not_supported_outlined),
              );
              if (_isDota) {
                return Center(
                  child: Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: qualityBorder ?? Colors.white,
                        width: 1.8,
                      ),
                    ),
                    child: image,
                  ),
                );
              }
              return Center(
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  heightFactor: 0.8,
                  child: image,
                ),
              );
            },
          ),
        ),
        if (badges.isNotEmpty)
          Positioned(
            left: badgeLeft,
            top: badgeTop,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: badgeMaxWidth),
              child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.start,
                spacing: 3,
                runSpacing: 3,
                children: badges,
              ),
            ),
          ),
        if (paintWearText != null && paintWearText!.isNotEmpty)
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.black.withOpacity(0.6),
              child: Text(
                '${'app.market.csgo.abradability'.tr}: $paintWearText',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        if (gems.isNotEmpty)
          Positioned(
            left: gemLeft,
            bottom: gemBottom,
            child: GemRow(gems: gems, size: gemSize),
          ),
        if (stickers.isNotEmpty)
          Positioned(
            left: stickerLeft,
            bottom: stickerBottomWithGem,
            child: StickerRow(stickers: stickers, size: stickerSize),
          ),
        if (showOnSaleBadge)
          Positioned(
            right: 6,
            bottom: onSaleBottom,
            child: Image.asset(
              'assets/images/game/item/on-sale.png',
              width: 18,
              height: 18,
            ),
          ),
        if (hasCountBadge)
          Positioned(
            right: 6,
            bottom: countBottom,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'x$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
    );
  }

  List<Widget> _buildBadges(BuildContext context, Color exteriorColor) {
    final badges = <Widget>[];
    if (disabledLabel != null && disabledLabel!.isNotEmpty) {
      badges.add(
        _TagChip(
          text: disabledLabel!,
          background: Theme.of(context).colorScheme.error,
        ),
      );
    }
    if (_isDota && rarity?.hasLabel == true) {
      badges.add(
        _TagChip(
          text: rarity!.label!,
          background: parseHexColor(rarity!.color) ?? Colors.black54,
        ),
      );
    }
    if (!_isDota && exterior?.hasLabel == true) {
      badges.add(_TagChip(text: exterior!.label!, background: exteriorColor));
    }
    if (cooldown != null && cooldown!.isNotEmpty) {
      badges.add(_TagChip(text: cooldown!, background: _chipColor(context)));
    }
    if (paintSeed != null && paintSeed!.isNotEmpty) {
      badges.add(_TagChip(text: paintSeed!, background: _chipColor(context)));
    }
    if (phase != null && phase!.isNotEmpty) {
      badges.add(_TagChip(text: phase!, background: _phaseColor(context)));
    }
    if (percentage != null && percentage!.isNotEmpty) {
      final text = percentage!.contains('%') ? percentage! : '$percentage%';
      badges.add(_TagChip(text: text, background: _chipColor(context)));
    }
    return badges;
  }

  Color _chipColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary.withOpacity(0.85);
  }

  Color _phaseColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary.withOpacity(0.85);
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text, required this.background});

  final String text;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 9.5),
      ),
    );
  }
}
