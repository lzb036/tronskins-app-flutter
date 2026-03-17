import 'dart:math' as math;

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
    this.alwaysShowCount = false,
    this.selected = false,
    this.showOnSaleBadge = false,
    this.disabledLabel,
    this.stickers = const [],
    this.gems = const [],
    this.stickerBottomOffset = 0,
    this.onSaleBottomOffset = 0,
    this.avoidTopLeftBadgeOverlap = false,
    this.compactTopLeftBadges = false,
    this.showTopBadges = true,
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
  final bool alwaysShowCount;
  final bool selected;
  final bool showOnSaleBadge;
  final String? disabledLabel;
  final List<GameItemSticker> stickers;
  final List<GameItemGem> gems;
  final double stickerBottomOffset;
  final double onSaleBottomOffset;
  final bool avoidTopLeftBadgeOverlap;
  final bool compactTopLeftBadges;
  final bool showTopBadges;

  bool get _isDota => appId == 570;

  @override
  Widget build(BuildContext context) {
    final bgAsset = _isDota ? null : rarityBgAsset(rarity?.color);
    final qualityBorder = qualityBorderColor(quality?.color);
    final exteriorColor = parseHexColor(exterior?.color) ?? Colors.black54;
    final badges = showTopBadges
        ? _buildBadges(context, exteriorColor, compact: compactTopLeftBadges)
        : const <Widget>[];
    final hasCountBadge =
        count != null && count! > 0 && (count! > 1 || alwaysShowCount);
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
    final badgeLeft = compactTopLeftBadges ? 3.0 : (_isDota ? 4.0 : 6.0);
    final badgeTop = compactTopLeftBadges ? 3.0 : 4.0;
    final badgeMaxWidth = compactTopLeftBadges
        ? (_isDota ? 96.0 : 72.0)
        : (_isDota ? 130.0 : 145.0);
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
              final badgeCount = badges.length;
              final imagePadding = _imagePaddingForBadges(
                constraints,
                badgeCount,
              );
              final imageSizeFactor = _imageSizeFactorForBadges(badgeCount);
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
                return Padding(
                  padding: imagePadding,
                  child: Center(
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
                  ),
                );
              }
              return Padding(
                padding: imagePadding,
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: imageSizeFactor,
                    heightFactor: imageSizeFactor,
                    child: image,
                  ),
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
              color: Colors.black.withValues(alpha: 0.6),
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
                color: Colors.black.withValues(alpha: 0.6),
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

  List<Widget> _buildBadges(
    BuildContext context,
    Color exteriorColor, {
    bool compact = false,
  }) {
    final badges = <Widget>[];
    if (disabledLabel != null && disabledLabel!.isNotEmpty) {
      badges.add(
        _TagChip(
          text: disabledLabel!,
          background: Theme.of(context).colorScheme.error,
          compact: compact,
        ),
      );
    }
    if (_isDota && rarity?.hasLabel == true) {
      badges.add(
        _TagChip(
          text: rarity!.label!,
          background: parseHexColor(rarity!.color) ?? Colors.black54,
          compact: compact,
        ),
      );
    }
    if (!_isDota && exterior?.hasLabel == true) {
      badges.add(
        _TagChip(
          text: exterior!.label!,
          background: exteriorColor,
          compact: compact,
        ),
      );
    }
    if (cooldown != null && cooldown!.isNotEmpty) {
      badges.add(
        _TagChip(
          text: cooldown!,
          background: _chipColor(context),
          compact: compact,
        ),
      );
    }
    if (paintSeed != null && paintSeed!.isNotEmpty) {
      badges.add(
        _TagChip(
          text: paintSeed!,
          background: _chipColor(context),
          compact: compact,
        ),
      );
    }
    if (phase != null && phase!.isNotEmpty) {
      badges.add(
        _TagChip(
          text: phase!,
          background: _phaseColor(context),
          compact: compact,
        ),
      );
    }
    if (percentage != null && percentage!.isNotEmpty) {
      final text = percentage!.contains('%') ? percentage! : '$percentage%';
      badges.add(
        _TagChip(text: text, background: _chipColor(context), compact: compact),
      );
    }
    return badges;
  }

  Color _chipColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.85);
  }

  Color _phaseColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.85);
  }

  EdgeInsets _imagePaddingForBadges(
    BoxConstraints constraints,
    int badgeCount,
  ) {
    if (!avoidTopLeftBadgeOverlap || badgeCount == 0) {
      return EdgeInsets.zero;
    }
    final leftBase = compactTopLeftBadges
        ? (badgeCount == 1 ? 14.0 : 18.0)
        : (badgeCount == 1 ? 10.0 : 14.0);
    final topBase = compactTopLeftBadges
        ? (badgeCount == 1 ? 8.0 : 14.0)
        : (badgeCount == 1 ? 6.0 : 12.0);
    return EdgeInsets.only(
      left: math.min(
        leftBase,
        constraints.maxWidth * (compactTopLeftBadges ? 0.24 : 0.18),
      ),
      top: math.min(
        topBase,
        constraints.maxHeight * (compactTopLeftBadges ? 0.28 : 0.24),
      ),
    );
  }

  double _imageSizeFactorForBadges(int badgeCount) {
    if (!avoidTopLeftBadgeOverlap || badgeCount == 0) {
      return _isDota ? 1.0 : 0.8;
    }
    if (_isDota) {
      return 1.0;
    }
    if (compactTopLeftBadges) {
      return badgeCount == 1 ? 0.84 : 0.8;
    }
    return badgeCount == 1 ? 0.9 : 0.86;
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.text,
    required this.background,
    this.compact = false,
  });

  final String text;
  final Color background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final effectiveBackground = compact
        ? background.withValues(alpha: 0.84)
        : background;
    final foreground = compact ? const Color(0xFFD6E38B) : Colors.white;
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(compact ? 2 : 4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: compact ? 8.2 : 9.5,
          fontWeight: compact ? FontWeight.w500 : FontWeight.w400,
          height: 1,
        ),
      ),
    );
  }
}
