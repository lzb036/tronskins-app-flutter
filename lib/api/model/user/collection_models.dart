import 'package:tronskins_app/api/model/market/market_models.dart';

class CollectionPager {
  final int page;
  final int pageSize;
  final int total;

  const CollectionPager({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory CollectionPager.fromJson(Map<String, dynamic> json) {
    return CollectionPager(
      page: _asInt(json['page']) ?? 1,
      pageSize: _asInt(json['pageSize']) ?? 20,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

class CollectionListResponse<T> {
  final List<T> items;
  final CollectionPager? pager;

  const CollectionListResponse({required this.items, this.pager});

  factory CollectionListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) mapper, {
    String listKey = 'list',
  }) {
    final rawList = json[listKey];
    final items = rawList is List
        ? rawList.whereType<Map<String, dynamic>>().map(mapper).toList()
        : <T>[];
    final rawPager = json['pager'];
    final pager = rawPager is Map<String, dynamic>
        ? CollectionPager.fromJson(rawPager)
        : null;
    return CollectionListResponse(items: items, pager: pager);
  }
}

class CollectionTemplateItem {
  final Map<String, dynamic> raw;
  final int? appId;
  final int? schemaId;
  final String? marketName;
  final String? marketHashName;
  final String? imageUrl;
  final double? sellMinPrice;
  final double? buyMaxPrice;
  final MarketItemTags? tags;

  const CollectionTemplateItem({
    required this.raw,
    this.appId,
    this.schemaId,
    this.marketName,
    this.marketHashName,
    this.imageUrl,
    this.sellMinPrice,
    this.buyMaxPrice,
    this.tags,
  });

  factory CollectionTemplateItem.fromJson(Map<String, dynamic> json) {
    return CollectionTemplateItem(
      raw: json,
      appId: _asInt(json['appId'] ?? json['app_id'] ?? json['appid']),
      schemaId: _asInt(json['schemaId'] ?? json['schema_id'] ?? json['id']),
      marketName:
          json['marketName']?.toString() ?? json['market_name']?.toString(),
      marketHashName:
          json['marketHashName']?.toString() ??
          json['market_hash_name']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      sellMinPrice: _asDouble(
        json['sellMinPrice'] ?? json['sell_min'] ?? json['sellMin'],
      ),
      buyMaxPrice: _asDouble(
        json['buyMaxPrice'] ?? json['buy_max'] ?? json['buyMax'],
      ),
      tags: json['tags'] is Map<String, dynamic>
          ? MarketItemTags.fromJson(json['tags'] as Map<String, dynamic>)
          : null,
    );
  }

  MarketItemEntity toMarketItemEntity() {
    return MarketItemEntity(
      id: schemaId,
      schemaId: schemaId,
      appId: appId,
      marketName: marketName,
      marketHashName: marketHashName,
      imageUrl: imageUrl,
      marketPrice: sellMinPrice,
      tags: tags,
    );
  }
}

class CollectionFavoriteItem {
  final Map<String, dynamic> raw;
  final int? itemId;
  final int? appId;
  final int? schemaId;
  final String? marketName;
  final String? marketHashName;
  final String? imageUrl;
  final double? price;
  final int? status;
  final String? statusName;
  final bool favorited;
  final bool own;
  final String? percentage;
  final String? phase;
  final String? paintWear;
  final String? paintSeed;
  final String? paintIndex;
  final MarketItemTags? tags;

  const CollectionFavoriteItem({
    required this.raw,
    this.itemId,
    this.appId,
    this.schemaId,
    this.marketName,
    this.marketHashName,
    this.imageUrl,
    this.price,
    this.status,
    this.statusName,
    this.favorited = true,
    this.own = false,
    this.percentage,
    this.phase,
    this.paintWear,
    this.paintSeed,
    this.paintIndex,
    this.tags,
  });

  factory CollectionFavoriteItem.fromJson(Map<String, dynamic> json) {
    final appId = _asInt(json['appId'] ?? json['app_id'] ?? json['appid']);
    final asset = _pickAsset(json, appId);

    String? pickText(List<String> keys) {
      for (final key in keys) {
        final value = json[key] ?? asset?[key];
        if (value != null) {
          return value.toString();
        }
      }
      return null;
    }

    return CollectionFavoriteItem(
      raw: json,
      itemId: _asInt(json['itemId'] ?? json['item_id'] ?? json['id']),
      appId: appId,
      schemaId: _asInt(
        json['schemaId'] ??
            json['schema_id'] ??
            asset?['schemaId'] ??
            asset?['schema_id'],
      ),
      marketName: pickText(['marketName', 'market_name']),
      marketHashName: pickText(['marketHashName', 'market_hash_name']),
      imageUrl: pickText(['imageUrl', 'image_url']),
      price: _asDouble(json['price'] ?? json['market_price']),
      status: _asInt(json['status']),
      statusName: pickText(['statusName', 'status_name']),
      favorited: _asBool(
        json['favorited'] ?? json['favorite'] ?? json['isFavorited'] ?? true,
      ),
      own: _asBool(json['own'] ?? json['isOwn'] ?? json['Own']),
      percentage: pickText(['percentage']),
      phase: pickText(['phase']),
      paintWear: pickText(['paintWear', 'paint_wear']),
      paintSeed: pickText(['paintSeed', 'paint_seed']),
      paintIndex: pickText(['paintIndex', 'paint_index']),
      tags: json['tags'] is Map<String, dynamic>
          ? MarketItemTags.fromJson(json['tags'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic>? get asset => _pickAsset(raw, appId);

  dynamic get rawStatus => raw['status'];

  bool get hasStatusTag => _isJsTruthy(rawStatus);

  dynamic get stickerRaw => asset?['stickers'] ?? raw['stickers'];

  dynamic get keychainRaw => asset?['keychains'] ?? raw['keychains'];

  dynamic get gemRaw =>
      asset?['gemList'] ?? asset?['gems'] ?? raw['gemList'] ?? raw['gems'];

  MarketItemEntity toMarketItemEntity() {
    return MarketItemEntity(
      id: schemaId,
      schemaId: schemaId,
      appId: appId,
      marketName: marketName,
      marketHashName: marketHashName,
      imageUrl: imageUrl,
      marketPrice: price,
      paintSeed: paintSeed,
      paintIndex: paintIndex,
      paintWear: paintWear,
      percentage: percentage,
      phase: phase,
      tags: tags,
    );
  }
}

Map<String, dynamic>? _pickAsset(Map<String, dynamic> json, int? appId) {
  if (appId == 730) {
    return _asMap(json['csgoAsset'] ?? json['csgo_asset']);
  }
  if (appId == 440) {
    return _asMap(json['tf2Asset'] ?? json['tf2_asset']);
  }
  if (appId == 570) {
    return _asMap(json['dota2Asset'] ?? json['dota2_asset']);
  }
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
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

double? _asDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final normalized = value.toString().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

bool _isJsTruthy(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    return value.isNotEmpty;
  }
  return true;
}
