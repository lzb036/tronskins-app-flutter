class MarketItemTag {
  final String? name;
  final String? localizedName;
  final String? color;
  final String? key;

  const MarketItemTag({this.name, this.localizedName, this.color, this.key});

  factory MarketItemTag.fromJson(Map<String, dynamic> json) {
    final define = json['define'];
    final defineKey = define is Map<String, dynamic> ? define['key'] : null;
    return MarketItemTag(
      name: json['name']?.toString(),
      localizedName: json['localized_name']?.toString(),
      color: json['color']?.toString(),
      key: defineKey?.toString(),
    );
  }
}

class MarketItemTags {
  final MarketItemTag? quality;
  final MarketItemTag? exterior;
  final MarketItemTag? rarity;
  final MarketItemTag? type;
  final MarketItemTag? hero;
  final MarketItemTag? slot;
  final MarketItemTag? itemSet;
  final MarketItemTag? weapon;

  const MarketItemTags({
    this.quality,
    this.exterior,
    this.rarity,
    this.type,
    this.hero,
    this.slot,
    this.itemSet,
    this.weapon,
  });

  factory MarketItemTags.fromJson(Map<String, dynamic> json) {
    MarketItemTag? parseTag(String key) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return MarketItemTag.fromJson(value);
      }
      return null;
    }

    return MarketItemTags(
      quality: parseTag('quality'),
      exterior: parseTag('exterior'),
      rarity: parseTag('rarity'),
      type: parseTag('type'),
      hero: parseTag('hero'),
      slot: parseTag('slot'),
      itemSet: parseTag('itemSet'),
      weapon: parseTag('weapon'),
    );
  }
}

class MarketItemEntity {
  final int? id;
  final int? schemaId;
  final int? appId;
  final String? marketName;
  final String? marketHashName;
  final String? imageUrl;
  final double? marketPrice;
  final int? sellNum;
  final String? cd;
  final String? paintSeed;
  final String? paintIndex;
  final String? paintWear;
  final String? percentage;
  final String? phase;
  final String? tier;
  final String? fireIce;
  final MarketItemTags? tags;

  const MarketItemEntity({
    this.id,
    this.schemaId,
    this.appId,
    this.marketName,
    this.marketHashName,
    this.imageUrl,
    this.marketPrice,
    this.sellNum,
    this.cd,
    this.paintSeed,
    this.paintIndex,
    this.paintWear,
    this.percentage,
    this.phase,
    this.tier,
    this.fireIce,
    this.tags,
  });

  factory MarketItemEntity.fromJson(Map<String, dynamic> json) {
    final csgoAsset = json['csgoAsset'];
    final csgoMap = csgoAsset is Map<String, dynamic>
        ? csgoAsset
        : <String, dynamic>{};

    dynamic pickValue(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return json[key];
        }
        if (csgoMap.containsKey(key) && csgoMap[key] != null) {
          return csgoMap[key];
        }
      }
      return null;
    }

    return MarketItemEntity(
      id: _asInt(json['id']),
      schemaId: _asInt(json['schema_id'] ?? json['schemaId']),
      appId: _asInt(json['app_id'] ?? json['appId']),
      marketName: json['market_name']?.toString(),
      marketHashName: json['market_hash_name']?.toString(),
      imageUrl: json['image_url']?.toString(),
      marketPrice: _asDouble(json['market_price'] ?? json['price']),
      sellNum: _asInt(json['sell_num']),
      cd: json['cd']?.toString(),
      paintSeed: pickValue(['paintSeed', 'paint_seed'])?.toString(),
      paintIndex: pickValue(['paintIndex', 'paint_index'])?.toString(),
      paintWear: pickValue(['paintWear', 'paint_wear'])?.toString(),
      percentage: pickValue(['percentage'])?.toString(),
      phase: pickValue(['phase'])?.toString(),
      tier: pickValue(['tier'])?.toString(),
      fireIce: pickValue(['fireIce', 'fire_ice'])?.toString(),
      tags: json['tags'] is Map<String, dynamic>
          ? MarketItemTags.fromJson(json['tags'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MarketPricePoint {
  final int time;
  final double price;

  const MarketPricePoint({required this.time, required this.price});

  factory MarketPricePoint.fromJson(Map<String, dynamic> json) {
    return MarketPricePoint(
      time: _asInt(json['time']) ?? 0,
      price: _asDouble(json['price']) ?? 0,
    );
  }
}

class MarketPriceTrendData {
  final List<MarketPricePoint> priceInfos;

  const MarketPriceTrendData({required this.priceInfos});

  factory MarketPriceTrendData.fromJson(Map<String, dynamic> json) {
    final raw = json['priceInfos'];
    final list = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(MarketPricePoint.fromJson)
              .toList()
        : <MarketPricePoint>[];
    return MarketPriceTrendData(priceInfos: list);
  }
}

class MarketPager {
  final int page;
  final int pageSize;
  final int total;

  const MarketPager({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory MarketPager.fromJson(Map<String, dynamic> json) {
    return MarketPager(
      page: _asInt(json['page']) ?? 1,
      pageSize: _asInt(json['pageSize']) ?? 10,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

class MarketUserInfo {
  final String? avatar;
  final String? nickname;
  final String? uuid;

  const MarketUserInfo({this.avatar, this.nickname, this.uuid});

  factory MarketUserInfo.fromJson(Map<String, dynamic> json) {
    return MarketUserInfo(
      avatar: json['avatar']?.toString(),
      nickname: json['nickname']?.toString(),
      uuid: json['uuid']?.toString(),
    );
  }
}

class MarketSchemaInfo {
  final Map<String, dynamic> raw;
  final String? imageUrl;
  final String? marketName;
  final String? marketHashName;
  final int? appId;
  final int? schemaId;
  final MarketItemTags? tags;

  const MarketSchemaInfo({
    this.raw = const {},
    this.imageUrl,
    this.marketName,
    this.marketHashName,
    this.appId,
    this.schemaId,
    this.tags,
  });

  factory MarketSchemaInfo.fromJson(Map<String, dynamic> json) {
    return MarketSchemaInfo(
      raw: json,
      appId: _asInt(json['app_id'] ?? json['appId']),
      schemaId: _asInt(json['schema_id'] ?? json['schemaId'] ?? json['id']),
      imageUrl: json['image_url']?.toString(),
      marketName: json['market_name']?.toString(),
      marketHashName: json['market_hash_name']?.toString(),
      tags: json['tags'] is Map<String, dynamic>
          ? MarketItemTags.fromJson(json['tags'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MarketListItem {
  final Map<String, dynamic> raw;
  final int? id;
  final int? appId;
  final int? schemaId;
  final int? userId;
  final bool? own;
  final bool? favorited;
  final String? marketHashName;
  final double? price;
  final String? typeName;
  final int? createTime;

  const MarketListItem({
    this.raw = const {},
    this.id,
    this.appId,
    this.schemaId,
    this.userId,
    this.own,
    this.favorited,
    this.marketHashName,
    this.price,
    this.typeName,
    this.createTime,
  });

  factory MarketListItem.fromJson(Map<String, dynamic> json) {
    return MarketListItem(
      raw: json,
      id: _asInt(json['id']),
      appId: _asInt(json['app_id'] ?? json['appId']),
      schemaId: _asInt(json['schema_id'] ?? json['schemaId']),
      userId: _asInt(json['userId'] ?? json['user_id']),
      own: _asBool(json['own'] ?? json['isOwn'] ?? json['Own']),
      favorited: _asBool(
        json['favorited'] ?? json['favorite'] ?? json['isFavorited'],
      ),
      marketHashName: json['market_hash_name']?.toString(),
      price: _asDouble(json['price']),
      typeName: json['typeName']?.toString(),
      createTime: _asInt(json['create_time']),
    );
  }
}

class MarketListResponse {
  final List<MarketListItem> items;
  final Map<String, MarketUserInfo> users;
  final Map<String, MarketSchemaInfo> schemas;
  final Map<String, dynamic> stickers;
  final MarketPager? pager;

  const MarketListResponse({
    required this.items,
    required this.users,
    required this.schemas,
    required this.stickers,
    this.pager,
  });

  factory MarketListResponse.fromJson(
    Map<String, dynamic> json, {
    String listKey = 'details',
  }) {
    final rawList = json[listKey];
    final items = rawList is List
        ? rawList
              .whereType<Map<String, dynamic>>()
              .map(MarketListItem.fromJson)
              .toList()
        : <MarketListItem>[];

    final rawUsers = json['users'];
    final users = <String, MarketUserInfo>{};
    if (rawUsers is Map<String, dynamic>) {
      rawUsers.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          users[key] = MarketUserInfo.fromJson(value);
        }
      });
    }

    final rawSchemas = json['schemas'];
    final schemas = <String, MarketSchemaInfo>{};
    if (rawSchemas is Map<String, dynamic>) {
      rawSchemas.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          schemas[key] = MarketSchemaInfo.fromJson(value);
        }
      });
    }

    final rawStickers = json['stickers'];
    final stickers = <String, dynamic>{};
    if (rawStickers is Map) {
      rawStickers.forEach((key, value) {
        stickers[key.toString()] = value;
      });
    }

    final rawPager = json['pager'];
    final pager = rawPager is Map<String, dynamic>
        ? MarketPager.fromJson(rawPager)
        : null;

    return MarketListResponse(
      items: items,
      users: users,
      schemas: schemas,
      stickers: stickers,
      pager: pager,
    );
  }
}

class MarketSchemaListResponse {
  final List<MarketItemEntity> items;
  final MarketPager? pager;

  const MarketSchemaListResponse({required this.items, this.pager});

  factory MarketSchemaListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['list'];
    final items = rawList is List
        ? rawList
              .whereType<Map<String, dynamic>>()
              .map(MarketItemEntity.fromJson)
              .toList()
        : <MarketItemEntity>[];
    final rawPager = json['pager'];
    final pager = rawPager is Map<String, dynamic>
        ? MarketPager.fromJson(rawPager)
        : null;
    return MarketSchemaListResponse(items: items, pager: pager);
  }
}

class MarketTemplateSchema {
  final Map<String, dynamic> raw;
  final int? appId;
  final int? schemaId;
  final String? marketName;
  final String? marketHashName;
  final String? imageUrl;
  final double? sellMin;
  final double? sellMax;
  final double? buyMin;
  final double? buyMax;
  final double? referencePrice;
  final int? sellNum;
  final int? buyNum;
  final MarketItemTags? tags;

  const MarketTemplateSchema({
    required this.raw,
    this.appId,
    this.schemaId,
    this.marketName,
    this.marketHashName,
    this.imageUrl,
    this.sellMin,
    this.sellMax,
    this.buyMin,
    this.buyMax,
    this.referencePrice,
    this.sellNum,
    this.buyNum,
    this.tags,
  });

  factory MarketTemplateSchema.fromJson(Map<String, dynamic> json) {
    return MarketTemplateSchema(
      raw: json,
      appId: _asInt(json['app_id'] ?? json['appId']),
      schemaId: _asInt(json['schema_id'] ?? json['schemaId'] ?? json['id']),
      marketName: json['market_name']?.toString(),
      marketHashName: json['market_hash_name']?.toString(),
      imageUrl: json['image_url']?.toString(),
      sellMin: _asDouble(json['sell_min']),
      sellMax: _asDouble(json['sell_max']),
      buyMin: _asDouble(json['buy_min']),
      buyMax: _asDouble(json['buy_max']),
      referencePrice: _asDouble(json['reference_price']),
      sellNum: _asInt(json['sell_num']),
      buyNum: _asInt(json['buy_num']),
      tags: json['tags'] is Map<String, dynamic>
          ? MarketItemTags.fromJson(json['tags'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MarketTemplateDetail {
  final MarketTemplateSchema? schema;
  final Map<String, dynamic>? qualityMap;
  final List<dynamic>? paintKits;
  final bool? isCollected;

  const MarketTemplateDetail({
    this.schema,
    this.qualityMap,
    this.paintKits,
    this.isCollected,
  });

  factory MarketTemplateDetail.fromJson(Map<String, dynamic> json) {
    final schemaRaw = json['schema'];
    return MarketTemplateDetail(
      schema: schemaRaw is Map<String, dynamic>
          ? MarketTemplateSchema.fromJson(schemaRaw)
          : null,
      qualityMap: json['map'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['map'] as Map<String, dynamic>)
          : null,
      paintKits: json['paintKits'] is List ? json['paintKits'] as List : null,
      isCollected: json['isCollected'] == true,
    );
  }
}

class BuyRemainInfo {
  final int? purchaseNum;
  final int? remainNum;

  const BuyRemainInfo({this.purchaseNum, this.remainNum});

  factory BuyRemainInfo.fromJson(Map<String, dynamic> json) {
    return BuyRemainInfo(
      purchaseNum: _asInt(json['purchaseNum']),
      remainNum: _asInt(json['remainNum']),
    );
  }
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
  final text = value.toString().toLowerCase();
  return text == 'true' || text == '1';
}
