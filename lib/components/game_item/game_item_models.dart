import 'package:flutter/material.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';

class TagInfo {
  final String? name;
  final String? label;
  final String? color;

  const TagInfo({
    this.name,
    this.label,
    this.color,
  });

  bool get hasLabel => label != null && label!.isNotEmpty;

  static TagInfo? fromMarketTag(MarketItemTag? tag) {
    if (tag == null) {
      return null;
    }
    return TagInfo(
      name: tag.name,
      label: tag.localizedName,
      color: tag.color,
    );
  }

  static TagInfo? fromRaw(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return TagInfo(
        name: raw['name']?.toString(),
        label: raw['localized_name']?.toString() ??
            raw['localizedName']?.toString(),
        color: raw['color']?.toString(),
      );
    }
    return null;
  }
}

class GameItemSticker {
  final String imageUrl;

  const GameItemSticker(this.imageUrl);
}

class GameItemGem {
  final String imageUrl;
  final Color? borderColor;

  const GameItemGem({
    required this.imageUrl,
    this.borderColor,
  });
}

List<GameItemSticker> parseStickerList(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  final stickers = <GameItemSticker>[];
  for (final item in raw) {
    final url = _extractImageUrl(item);
    if (url == null || url.isEmpty) {
      continue;
    }
    stickers.add(GameItemSticker(_normalizeStickerUrl(url)));
  }
  return stickers;
}

List<GameItemGem> parseGemList(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  final gems = <GameItemGem>[];
  for (final item in raw) {
    if (item is Map<String, dynamic>) {
      final url = item['imageUrl']?.toString() ??
          item['image_url']?.toString() ??
          item['image']?.toString();
      if (url == null || url.isEmpty) {
        continue;
      }
      final border = _parseColor(item['borderColor']?.toString() ??
          item['border_color']?.toString());
      gems.add(GameItemGem(imageUrl: url, borderColor: border));
    } else if (item is String && item.isNotEmpty) {
      gems.add(GameItemGem(imageUrl: item));
    }
  }
  return gems;
}

String? _extractImageUrl(dynamic item) {
  if (item is String) {
    return item;
  }
  if (item is Map<String, dynamic>) {
    return item['image_url']?.toString() ??
        item['imageUrl']?.toString() ??
        item['image']?.toString();
  }
  return null;
}

String _normalizeStickerUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  const head = 'https://community.steamstatic.com/economy/image/';
  return '$head$url';
}

Color? _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) {
    return null;
  }
  final normalized = hex.replaceAll('#', '');
  if (normalized.length == 6) {
    return Color(int.parse('FF$normalized', radix: 16));
  }
  return null;
}
