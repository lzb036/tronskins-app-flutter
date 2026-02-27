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

  bool get _isDota => appId == 570;

  @override
  Widget build(BuildContext context) {
    final bgAsset = _isDota ? null : rarityBgAsset(rarity?.color);
    final qualityBorder = _isDota ? null : qualityBorderColor(quality?.color);
    final exteriorColor = parseHexColor(exterior?.color) ?? Colors.black54;
    final badges = _buildBadges(context, exteriorColor);
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
                placeholder: (context, _) =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (context, _, __) =>
                    const Icon(Icons.image_not_supported_outlined),
              );
              if (_isDota) {
                return Center(
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
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
            left: 6,
            top: 6,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: badges,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        if (gems.isNotEmpty)
          Positioned(
            left: 6,
            bottom: 10,
            child: GemRow(gems: gems, size: 16),
          ),
        if (stickers.isNotEmpty)
          Positioned(
            right: 6,
            bottom: 10,
            child: StickerRow(stickers: stickers, size: 16),
          ),
        if (showOnSaleBadge)
          Positioned(
            right: 6,
            bottom: stickers.isNotEmpty ? 32 : 10,
            child: Image.asset(
              'assets/images/game/item/on-sale.png',
              width: 18,
              height: 18,
            ),
          ),
        if (count != null && count! > 1)
          Positioned(
            right: 6,
            bottom: 6,
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
  const _TagChip({
    required this.text,
    required this.background,
  });

  final String text;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }
}
