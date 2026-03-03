class ShopUserInfo {
  final String? id;
  final String? uuid;
  final String? avatar;
  final String? nickname;
  final int? level;
  final int? yearsLevel;

  const ShopUserInfo({
    this.id,
    this.uuid,
    this.avatar,
    this.nickname,
    this.level,
    this.yearsLevel,
  });

  factory ShopUserInfo.fromJson(Map<String, dynamic> json) {
    return ShopUserInfo(
      id: json['id']?.toString(),
      uuid: json['uuid']?.toString(),
      avatar: json['avatar']?.toString(),
      nickname: json['nickname']?.toString(),
      level: _asInt(json['level']),
      yearsLevel: _asInt(json['yearsLevel']),
    );
  }
}

class ShopSchemaInfo {
  final String? marketName;
  final String? marketHashName;
  final String? imageUrl;
  final Map<String, dynamic> raw;

  const ShopSchemaInfo({
    required this.raw,
    this.marketName,
    this.marketHashName,
    this.imageUrl,
  });

  factory ShopSchemaInfo.fromJson(Map<String, dynamic> json) {
    return ShopSchemaInfo(
      raw: json,
      marketName: json['market_name']?.toString(),
      marketHashName: json['market_hash_name']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }
}

class ShopItemAsset {
  final Map<String, dynamic> raw;
  final int? id;
  final int? appId;
  final int? schemaId;
  final String? marketName;
  final String? marketHashName;
  final String? imageUrl;
  final double? price;
  final int? count;
  final int? userId;
  final int? status;
  final String? statusName;
  final int? createTime;

  const ShopItemAsset({
    required this.raw,
    this.id,
    this.appId,
    this.schemaId,
    this.marketName,
    this.marketHashName,
    this.imageUrl,
    this.price,
    this.count,
    this.userId,
    this.status,
    this.statusName,
    this.createTime,
  });

  factory ShopItemAsset.fromJson(Map<String, dynamic> json) {
    final appId = _asInt(json['app_id'] ?? json['appId']);
    final nested = _pickAsset(json, appId);
    return ShopItemAsset(
      raw: json,
      id: _asInt(json['id']),
      appId: appId,
      schemaId: _asInt(json['schema_id'] ?? nested?['schema_id']),
      marketName: json['market_name']?.toString() ?? nested?['market_name'],
      marketHashName:
          json['market_hash_name']?.toString() ?? nested?['market_hash_name'],
      imageUrl: json['image_url']?.toString() ?? nested?['image_url'],
      price: _asDouble(json['price'] ?? json['total_price']),
      count: _asInt(json['count']),
      userId: _asInt(json['userId'] ?? json['user_id']),
      status: _asInt(json['status']),
      statusName:
          json['statusName']?.toString() ?? json['status_name']?.toString(),
      createTime: _asInt(json['create_time'] ?? json['createTime']),
    );
  }

  Map<String, dynamic>? get asset => _pickAsset(raw, appId);
}

class ShopOrderDetail {
  final Map<String, dynamic> raw;
  final int? schemaId;
  final String? marketName;
  final String? marketHashName;
  final String? imageUrl;
  final double? price;
  final double? totalPrice;
  final int? count;
  final double? paintWear;
  final int? type;

  const ShopOrderDetail({
    required this.raw,
    this.schemaId,
    this.marketName,
    this.marketHashName,
    this.imageUrl,
    this.price,
    this.totalPrice,
    this.count,
    this.paintWear,
    this.type,
  });

  factory ShopOrderDetail.fromJson(Map<String, dynamic> json) {
    return ShopOrderDetail(
      raw: json,
      schemaId: _asInt(json['schema_id'] ?? json['schemaId']),
      marketName:
          json['market_name']?.toString() ?? json['marketName']?.toString(),
      marketHashName:
          json['market_hash_name']?.toString() ??
          json['marketHashName']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      price: _asDouble(json['price']),
      totalPrice: _asDouble(json['total_price']),
      count: _asInt(json['count']),
      paintWear: _asDouble(json['paint_wear'] ?? json['paintWear']),
      type: _asInt(json['type']),
    );
  }
}

class ShopOrderItem {
  final Map<String, dynamic> raw;
  final int? id;
  final int? status;
  final String? statusName;
  final int? createTime;
  final int? changeTime;
  final double? price;
  final double? totalPrice;
  final int? nums;
  final int? protectionTime;
  final int? type;
  final String? tradeOfferId;
  final String? cancelDesc;
  final String? buyerId;
  final List<ShopOrderDetail> details;
  final ShopUserInfo? user;

  const ShopOrderItem({
    required this.raw,
    this.id,
    this.status,
    this.statusName,
    this.createTime,
    this.changeTime,
    this.price,
    this.totalPrice,
    this.nums,
    this.protectionTime,
    this.type,
    this.tradeOfferId,
    this.cancelDesc,
    this.buyerId,
    required this.details,
    this.user,
  });

  factory ShopOrderItem.fromJson(Map<String, dynamic> json) {
    final details = json['details'] is List
        ? (json['details'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ShopOrderDetail.fromJson)
              .toList()
        : <ShopOrderDetail>[];
    return ShopOrderItem(
      raw: json,
      id: _asInt(json['id']),
      status: _asInt(json['status']),
      statusName:
          json['statusName']?.toString() ?? json['status_name']?.toString(),
      createTime: _asInt(json['create_time'] ?? json['createTime']),
      changeTime: _asInt(json['change_time'] ?? json['changeTime']),
      price: _asDouble(json['price'] ?? json['total_price']),
      totalPrice: _asDouble(json['total_price'] ?? json['totalPrice']),
      nums: _asInt(json['nums'] ?? json['count']),
      protectionTime: _asInt(json['protection_time']),
      type: _asInt(json['type']),
      tradeOfferId:
          json['trade_offer_id']?.toString() ??
          json['tradeOfferId']?.toString(),
      cancelDesc: json['cancel_desc']?.toString(),
      buyerId: json['buyer']?.toString() ?? json['buyer_id']?.toString(),
      details: details,
      user: json['user'] is Map<String, dynamic>
          ? ShopUserInfo.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BuyRequestItem {
  final Map<String, dynamic> raw;
  final int? id;
  final int? appId;
  final int? schemaId;
  final double? price;
  final int? nums;
  final int? received;
  final int? need;
  final int? status;
  final String? statusName;
  final int? upTime;
  final int? createTime;
  final int? userId;
  final bool? own;
  final double? paintWearMin;
  final double? paintWearMax;
  final String? phase;
  final int? count;

  const BuyRequestItem({
    required this.raw,
    this.id,
    this.appId,
    this.schemaId,
    this.price,
    this.nums,
    this.received,
    this.need,
    this.status,
    this.statusName,
    this.upTime,
    this.createTime,
    this.userId,
    this.own,
    this.paintWearMin,
    this.paintWearMax,
    this.phase,
    this.count,
  });

  factory BuyRequestItem.fromJson(Map<String, dynamic> json) {
    return BuyRequestItem(
      raw: json,
      id: _asInt(json['id']),
      appId: _asInt(json['appId'] ?? json['app_id']),
      schemaId: _asInt(json['schema_id'] ?? json['schemaId']),
      price: _asDouble(json['price']),
      nums: _asInt(json['nums']),
      received: _asInt(json['received']),
      need: _asInt(json['need'] ?? json['nums']),
      status: _asInt(json['status']),
      statusName:
          json['statusName']?.toString() ?? json['status_name']?.toString(),
      upTime: _asInt(json['upTime'] ?? json['up_time'] ?? json['create_time']),
      createTime: _asInt(json['create_time'] ?? json['createTime']),
      userId: _asInt(json['userId'] ?? json['user_id']),
      own: _asBool(json['own']),
      paintWearMin: _asDouble(json['paint_wear_min'] ?? json['paintWearMin']),
      paintWearMax: _asDouble(json['paint_wear_max'] ?? json['paintWearMax']),
      phase: json['phase']?.toString(),
      count: _asInt(json['count']),
    );
  }
}

class ShopPager {
  final int page;
  final int pageSize;
  final int total;

  const ShopPager({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory ShopPager.fromJson(Map<String, dynamic> json) {
    return ShopPager(
      page: _asInt(json['page']) ?? 1,
      pageSize: _asInt(json['pageSize']) ?? 10,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

class ShopListResponse<T> {
  final List<T> items;
  final Map<String, ShopUserInfo> users;
  final Map<String, ShopSchemaInfo> schemas;
  final Map<String, dynamic> stickers;
  final ShopPager? pager;
  final int? total;
  final double? totalPrice;

  const ShopListResponse({
    required this.items,
    required this.users,
    required this.schemas,
    required this.stickers,
    this.pager,
    this.total,
    this.totalPrice,
  });

  factory ShopListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) mapper, {
    String listKey = 'list',
  }) {
    final rawList = json[listKey];
    final items = rawList is List
        ? rawList.whereType<Map<String, dynamic>>().map(mapper).toList()
        : <T>[];

    final rawUsers = json['users'];
    final users = <String, ShopUserInfo>{};
    if (rawUsers is Map<String, dynamic>) {
      rawUsers.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          users[key] = ShopUserInfo.fromJson(value);
        }
      });
    }

    final rawSchemas = json['schemas'];
    final schemas = <String, ShopSchemaInfo>{};
    if (rawSchemas is Map<String, dynamic>) {
      rawSchemas.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          schemas[key] = ShopSchemaInfo.fromJson(value);
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

    final pager = json['pager'] is Map<String, dynamic>
        ? ShopPager.fromJson(json['pager'] as Map<String, dynamic>)
        : null;

    return ShopListResponse(
      items: items,
      users: users,
      schemas: schemas,
      stickers: stickers,
      pager: pager,
      total: _asInt(json['total']) ?? pager?.total,
      totalPrice: _asDouble(json['totalPrice'] ?? json['total_price']),
    );
  }
}

class InventoryItem {
  final Map<String, dynamic> raw;
  final int? id;
  final int? appId;
  final int? schemaId;
  final String? marketName;
  final String? marketHashName;
  final String? imageUrl;
  final double? price;
  final bool? tradable;
  final bool? coolingDown;
  final String? cooldown;
  final double? paintWear;
  final String? paintSeed;
  final String? phase;
  final int? status;
  final int? count;

  const InventoryItem({
    required this.raw,
    this.id,
    this.appId,
    this.schemaId,
    this.marketName,
    this.marketHashName,
    this.imageUrl,
    this.price,
    this.tradable,
    this.coolingDown,
    this.cooldown,
    this.paintWear,
    this.paintSeed,
    this.phase,
    this.status,
    this.count,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      raw: json,
      id: _asInt(json['id']),
      appId: _asInt(json['app_id'] ?? json['appId']),
      schemaId: _asInt(json['schema_id'] ?? json['schemaId']),
      marketName: json['market_name']?.toString(),
      marketHashName: json['market_hash_name']?.toString(),
      imageUrl: json['image_url']?.toString(),
      price: _asDouble(json['price']),
      tradable: _asBool(json['tradeAble'] ?? json['tradable']),
      coolingDown: _asBool(json['cd'] ?? json['cooling']),
      cooldown: json['cd']?.toString(),
      paintWear: _asDouble(json['paint_wear'] ?? json['paintWear']),
      paintSeed:
          json['paint_seed']?.toString() ?? json['paintSeed']?.toString(),
      phase: json['phase']?.toString(),
      status: _asInt(json['status']),
      count: _asInt(json['count']) ?? 1,
    );
  }
}

class InventoryResponse {
  final List<InventoryItem> items;
  final Map<String, ShopSchemaInfo> schemas;
  final Map<String, dynamic> stickers;
  final ShopPager? pager;
  final int? total;
  final double? totalPrice;

  const InventoryResponse({
    required this.items,
    required this.schemas,
    required this.stickers,
    this.pager,
    this.total,
    this.totalPrice,
  });

  factory InventoryResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['assets'] ?? json['list'] ?? json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(InventoryItem.fromJson)
              .toList()
        : <InventoryItem>[];

    final rawSchemas = json['schemas'];
    final schemas = <String, ShopSchemaInfo>{};
    if (rawSchemas is Map<String, dynamic>) {
      rawSchemas.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          schemas[key] = ShopSchemaInfo.fromJson(value);
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

    final pager = json['pager'] is Map<String, dynamic>
        ? ShopPager.fromJson(json['pager'] as Map<String, dynamic>)
        : null;

    return InventoryResponse(
      items: items,
      schemas: schemas,
      stickers: stickers,
      pager: pager,
      total: _asInt(json['total']),
      totalPrice: _asDouble(json['total_price']),
    );
  }
}

Map<String, dynamic>? _pickAsset(Map<String, dynamic> json, int? appId) {
  if (appId == null) {
    return null;
  }
  if (appId == 730) {
    return json['csgoAsset'] is Map<String, dynamic>
        ? json['csgoAsset'] as Map<String, dynamic>
        : null;
  }
  if (appId == 440) {
    return json['tf2Asset'] is Map<String, dynamic>
        ? json['tf2Asset'] as Map<String, dynamic>
        : null;
  }
  if (appId == 570) {
    return json['dota2Asset'] is Map<String, dynamic>
        ? json['dota2Asset'] as Map<String, dynamic>
        : null;
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
  final text = value.toString().toLowerCase();
  return text == 'true' || text == '1';
}
