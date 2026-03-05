class WalletPager {
  final int page;
  final int pageSize;
  final int total;

  const WalletPager({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory WalletPager.fromJson(Map<String, dynamic> json) {
    return WalletPager(
      page: _asInt(json['page']) ?? 1,
      pageSize: _asInt(json['pageSize'] ?? json['page_size']) ?? 10,
      total: _asInt(json['total']) ?? 0,
    );
  }
}

class WalletListResponse<T> {
  final List<T> list;
  final WalletPager? pager;

  const WalletListResponse({
    required this.list,
    this.pager,
  });

  factory WalletListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) mapper, {
    String listKey = 'list',
  }) {
    final rawList = json[listKey];
    final list = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(mapper)
            .toList()
        : <T>[];

    final pager = json['pager'] is Map<String, dynamic>
        ? WalletPager.fromJson(json['pager'] as Map<String, dynamic>)
        : null;

    return WalletListResponse(list: list, pager: pager);
  }
}

class WalletFundFlowItem {
  final String? id;
  final String? serialNumber;
  final int? type;
  final String? typeName;
  final double? amount;
  final double? beforeBalance;
  final int? createTime;

  const WalletFundFlowItem({
    this.id,
    this.serialNumber,
    this.type,
    this.typeName,
    this.amount,
    this.beforeBalance,
    this.createTime,
  });

  factory WalletFundFlowItem.fromJson(Map<String, dynamic> json) {
    return WalletFundFlowItem(
      id: json['id']?.toString(),
      serialNumber: json['serialNumber']?.toString() ??
          json['serial_number']?.toString(),
      type: _asInt(json['type']),
      typeName: json['typeName']?.toString() ??
          json['type_name']?.toString(),
      amount: _asDouble(json['amount']),
      beforeBalance:
          _asDouble(json['beforeBalance'] ?? json['before_balance']),
      createTime: _asInt(json['createTime'] ?? json['create_time']),
    );
  }
}

class WalletLockedItem {
  final int? id;
  final double? amount;
  final double? giftAmount;
  final int? lockType;
  final int? lockAmount;
  final int? createTime;
  final dynamic lockTimeRaw;
  final dynamic createTimeRaw;

  const WalletLockedItem({
    this.id,
    this.amount,
    this.giftAmount,
    this.lockType,
    this.lockAmount,
    this.createTime,
    this.lockTimeRaw,
    this.createTimeRaw,
  });

  factory WalletLockedItem.fromJson(Map<String, dynamic> json) {
    final lockTimeRaw = json['lockAmount'] ??
        json['lock_amount'] ??
        json['lockTime'] ??
        json['lock_time'] ??
        json['lockedTime'] ??
        json['locked_time'];
    final createTimeRaw = json['createTime'] ??
        json['create_time'] ??
        json['createdAt'] ??
        json['created_at'] ??
        json['time'];

    return WalletLockedItem(
      id: _asInt(json['id']),
      amount: _asDouble(json['amount']),
      giftAmount: _asDouble(json['gift_amount'] ?? json['giftAmount']),
      lockType: _asInt(json['lockType'] ?? json['lock_type']),
      lockAmount: _asTimestamp(lockTimeRaw),
      createTime: _asTimestamp(createTimeRaw),
      lockTimeRaw: lockTimeRaw,
      createTimeRaw: createTimeRaw,
    );
  }
}

class WalletSchemaInfo {
  final Map<String, dynamic> raw;
  final int? id;
  final int? appId;
  final String? marketName;
  final String? marketHashName;
  final String? imageUrl;
  final double? sellMin;
  final double? buyMax;
  final double? paintWear;
  final List<dynamic>? stickers;

  const WalletSchemaInfo({
    required this.raw,
    this.id,
    this.appId,
    this.marketName,
    this.marketHashName,
    this.imageUrl,
    this.sellMin,
    this.buyMax,
    this.paintWear,
    this.stickers,
  });

  factory WalletSchemaInfo.fromJson(Map<String, dynamic> json) {
    return WalletSchemaInfo(
      raw: json,
      id: _asInt(json['id'] ?? json['schema_id']),
      appId: _asInt(json['app_id'] ?? json['appId']),
      marketName: json['market_name']?.toString(),
      marketHashName: json['market_hash_name']?.toString(),
      imageUrl: json['image_url']?.toString(),
      sellMin: _asDouble(json['sell_min']),
      buyMax: _asDouble(json['buy_max']),
      paintWear: _asDouble(json['paint_wear']),
      stickers: json['stickers'] is List ? json['stickers'] as List : null,
    );
  }
}

class WalletLockedOrder {
  final Map<String, dynamic> raw;
  final int? id;
  final int? appId;
  final int? schemaId;
  final double? price;
  final int? status;
  final String? buyerId;
  final String? sellerId;
  final String? tradeOfferId;
  final int? changeTime;
  final int? createTime;

  const WalletLockedOrder({
    required this.raw,
    this.id,
    this.appId,
    this.schemaId,
    this.price,
    this.status,
    this.buyerId,
    this.sellerId,
    this.tradeOfferId,
    this.changeTime,
    this.createTime,
  });

  factory WalletLockedOrder.fromJson(Map<String, dynamic> json) {
    return WalletLockedOrder(
      raw: json,
      id: _asInt(json['id']),
      appId: _asInt(json['app_id'] ?? json['appId']),
      schemaId: _asInt(json['schema_id'] ?? json['schemaId']),
      price: _asDouble(json['price'] ?? json['total_price']),
      status: _asInt(json['status']),
      buyerId: json['buyer']?.toString() ?? json['buyer_id']?.toString(),
      sellerId: json['seller']?.toString() ?? json['seller_id']?.toString(),
      tradeOfferId: json['trade_offer_id']?.toString() ??
          json['tradeOfferId']?.toString(),
      changeTime: _asInt(json['change_time'] ?? json['changeTime']),
      createTime: _asInt(json['create_time'] ?? json['createTime']),
    );
  }
}

class WalletLockedDetail {
  final WalletLockedOrder? order;
  final WalletSchemaInfo? schema;
  final Map<String, dynamic> users;
  final Map<String, dynamic> stickers;

  const WalletLockedDetail({
    this.order,
    this.schema,
    required this.users,
    required this.stickers,
  });

  factory WalletLockedDetail.fromJson(Map<String, dynamic> json) {
    final orderRaw = json['sellItem'];
    final schemaRaw = json['schema'];
    final usersRaw = json['users'];
    final stickersRaw = json['stickers'];
    return WalletLockedDetail(
      order: orderRaw is Map<String, dynamic>
          ? WalletLockedOrder.fromJson(orderRaw)
          : null,
      schema: schemaRaw is Map<String, dynamic>
          ? WalletSchemaInfo.fromJson(schemaRaw)
          : null,
      users: usersRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(usersRaw)
          : <String, dynamic>{},
      stickers: stickersRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(stickersRaw)
          : <String, dynamic>{},
    );
  }
}

class WalletOfficialWallet {
  final String? walletAddress;
  final int? remainTime;

  const WalletOfficialWallet({
    this.walletAddress,
    this.remainTime,
  });

  factory WalletOfficialWallet.fromJson(Map<String, dynamic> json) {
    return WalletOfficialWallet(
      walletAddress: json['walletAddress']?.toString() ??
          json['wallet_address']?.toString(),
      remainTime: _asInt(json['remainTime'] ?? json['remain_time']),
    );
  }
}

class WalletRechargeRecord {
  final String? id;
  final int? status;
  final String? statusName;
  final String? modeName;
  final double? amount;
  final int? createTime;

  const WalletRechargeRecord({
    this.id,
    this.status,
    this.statusName,
    this.modeName,
    this.amount,
    this.createTime,
  });

  factory WalletRechargeRecord.fromJson(Map<String, dynamic> json) {
    return WalletRechargeRecord(
      id: json['id']?.toString(),
      status: _asInt(json['status']),
      statusName: json['statusName']?.toString() ??
          json['status_name']?.toString(),
      modeName: json['modeName']?.toString() ?? json['mode_name']?.toString(),
      amount: _asDouble(json['amount']),
      createTime: _asInt(json['createTime'] ?? json['create_time']),
    );
  }
}

class WalletWithdrawRecord {
  final String? id;
  final int? status;
  final String? statusName;
  final double? amount;
  final String? account;
  final int? createTime;

  const WalletWithdrawRecord({
    this.id,
    this.status,
    this.statusName,
    this.amount,
    this.account,
    this.createTime,
  });

  factory WalletWithdrawRecord.fromJson(Map<String, dynamic> json) {
    return WalletWithdrawRecord(
      id: json['id']?.toString(),
      status: _asInt(json['status']),
      statusName: json['statusName']?.toString() ??
          json['status_name']?.toString(),
      amount: _asDouble(json['amount']),
      account: json['account']?.toString(),
      createTime: _asInt(json['createTime'] ?? json['create_time']),
    );
  }
}

class WalletWithdrawAddress {
  final String? id;
  final String? name;
  final String? account;

  const WalletWithdrawAddress({
    this.id,
    this.name,
    this.account,
  });

  factory WalletWithdrawAddress.fromJson(Map<String, dynamic> json) {
    return WalletWithdrawAddress(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      account: json['account']?.toString(),
    );
  }
}

class WalletIntegralRecord {
  final String? id;
  final int? type;
  final String? typeName;
  final int? value;
  final int? changedIntegral;
  final int? createTime;

  const WalletIntegralRecord({
    this.id,
    this.type,
    this.typeName,
    this.value,
    this.changedIntegral,
    this.createTime,
  });

  factory WalletIntegralRecord.fromJson(Map<String, dynamic> json) {
    return WalletIntegralRecord(
      id: json['id']?.toString(),
      type: _asInt(json['type']),
      typeName: json['typeName']?.toString() ??
          json['type_name']?.toString(),
      value: _asInt(json['value']),
      changedIntegral: _asInt(json['changedIntegral'] ??
          json['changed_integral'] ??
          json['afterIntegral']),
      createTime: _asInt(json['createTime'] ?? json['create_time']),
    );
  }
}

class WalletCouponItem {
  final int? type;
  final String? desc;
  final int? value;
  final int? validate;
  final int? couponsType;
  final String? typeName;

  const WalletCouponItem({
    this.type,
    this.desc,
    this.value,
    this.validate,
    this.couponsType,
    this.typeName,
  });

  factory WalletCouponItem.fromJson(Map<String, dynamic> json) {
    return WalletCouponItem(
      type: _asInt(json['type']),
      desc: json['desc']?.toString() ?? json['name']?.toString(),
      value: _asInt(json['value']),
      validate: _asInt(json['validate']),
      couponsType: _asInt(json['couponsType'] ?? json['coupons_type']),
      typeName: json['typeName']?.toString() ??
          json['type_name']?.toString(),
    );
  }
}

class WalletCouponRecord {
  final String? id;
  final String? typeName;
  final int? couponsType;
  final int? expireTime;

  const WalletCouponRecord({
    this.id,
    this.typeName,
    this.couponsType,
    this.expireTime,
  });

  factory WalletCouponRecord.fromJson(Map<String, dynamic> json) {
    return WalletCouponRecord(
      id: json['id']?.toString(),
      typeName: json['typeName']?.toString() ??
          json['type_name']?.toString(),
      couponsType: _asInt(json['couponsType'] ?? json['coupons_type']),
      expireTime: _asInt(json['expireTime'] ?? json['expire_time']),
    );
  }
}

class WalletLotteryPrize {
  final Map<String, dynamic> raw;
  final int? index;
  final int? prizeNumber;
  final String? label;
  final String? drawingLabel;
  final String? image;

  const WalletLotteryPrize({
    required this.raw,
    this.index,
    this.prizeNumber,
    this.label,
    this.drawingLabel,
    this.image,
  });

  factory WalletLotteryPrize.fromJson(Map<String, dynamic> json) {
    return WalletLotteryPrize(
      raw: json,
      index: _asInt(json['index'] ?? json['sort']),
      prizeNumber: _asInt(json['prizeNumber'] ?? json['prize_number']),
      label: json['label']?.toString() ??
          json['name']?.toString() ??
          json['title']?.toString(),
      drawingLabel: json['drawingLabel']?.toString(),
      image: json['image']?.toString() ?? json['img']?.toString(),
    );
  }
}

class WalletLotteryResult {
  final Map<String, dynamic> raw;
  final String? title;
  final String? description;
  final String? image;

  const WalletLotteryResult({
    required this.raw,
    this.title,
    this.description,
    this.image,
  });

  factory WalletLotteryResult.fromJson(Map<String, dynamic> json) {
    return WalletLotteryResult(
      raw: json,
      title: json['title']?.toString() ??
          json['name']?.toString() ??
          json['typeName']?.toString(),
      description: json['desc']?.toString() ?? json['description']?.toString(),
      image: json['image']?.toString() ?? json['img']?.toString(),
    );
  }
}

class WalletSettlementDetail {
  final Map<String, dynamic> raw;
  final int? appId;
  final int? schemaId;
  final String? marketName;
  final String? marketHashName;
  final String? imageUrl;
  final double? paintWear;
  final double? price;

  const WalletSettlementDetail({
    required this.raw,
    this.appId,
    this.schemaId,
    this.marketName,
    this.marketHashName,
    this.imageUrl,
    this.paintWear,
    this.price,
  });

  factory WalletSettlementDetail.fromJson(Map<String, dynamic> json) {
    return WalletSettlementDetail(
      raw: json,
      appId: _asInt(json['app_id'] ?? json['appId']),
      schemaId: _asInt(json['schema_id'] ?? json['schemaId']),
      marketName: json['market_name']?.toString() ??
          json['marketName']?.toString(),
      marketHashName: json['market_hash_name']?.toString() ??
          json['marketHashName']?.toString(),
      imageUrl: json['image_url']?.toString() ??
          json['imageUrl']?.toString(),
      paintWear: _asDouble(json['paint_wear'] ?? json['paintWear']),
      price: _asDouble(json['price']),
    );
  }
}

class WalletSettlementRecord {
  final Map<String, dynamic> raw;
  final String? id;
  final int? status;
  final double? price;
  final int? protectionTime;
  final List<WalletSettlementDetail> details;

  const WalletSettlementRecord({
    required this.raw,
    this.id,
    this.status,
    this.price,
    this.protectionTime,
    required this.details,
  });

  factory WalletSettlementRecord.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    final details = rawDetails is List
        ? rawDetails
            .whereType<Map<String, dynamic>>()
            .map(WalletSettlementDetail.fromJson)
            .toList()
        : <WalletSettlementDetail>[];
    return WalletSettlementRecord(
      raw: json,
      id: json['id']?.toString(),
      status: _asInt(json['status']),
      price: _asDouble(json['price'] ?? json['total_price']),
      protectionTime: _asInt(json['protection_time']),
      details: details,
    );
  }
}

class WalletSettlementResponse {
  final List<WalletSettlementRecord> records;
  final Map<String, WalletSchemaInfo> schemas;
  final Map<String, dynamic> users;
  final Map<String, dynamic> stickers;
  final WalletPager? pager;

  const WalletSettlementResponse({
    required this.records,
    required this.schemas,
    required this.users,
    required this.stickers,
    this.pager,
  });

  factory WalletSettlementResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['records'];
    final records = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(WalletSettlementRecord.fromJson)
            .toList()
        : <WalletSettlementRecord>[];

    final rawSchemas = json['schemas'];
    final schemas = <String, WalletSchemaInfo>{};
    if (rawSchemas is Map<String, dynamic>) {
      rawSchemas.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          schemas[key] = WalletSchemaInfo.fromJson(value);
        }
      });
    }

    final rawUsers = json['users'];
    final users = rawUsers is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawUsers)
        : <String, dynamic>{};

    final rawStickers = json['stickers'];
    final stickers = rawStickers is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawStickers)
        : <String, dynamic>{};

    final pager = json['pager'] is Map<String, dynamic>
        ? WalletPager.fromJson(json['pager'] as Map<String, dynamic>)
        : null;

    return WalletSettlementResponse(
      records: records,
      schemas: schemas,
      users: users,
      stickers: stickers,
      pager: pager,
    );
  }
}

class WalletShopEnableStatus {
  final bool isEnableRecharge;
  final bool isEnableWithdraw;

  const WalletShopEnableStatus({
    required this.isEnableRecharge,
    required this.isEnableWithdraw,
  });

  factory WalletShopEnableStatus.fromJson(Map<String, dynamic> json) {
    return WalletShopEnableStatus(
      isEnableRecharge: _asBool(json['isEnableRecharge']) ||
          _asBool(json['is_enable_recharge']),
      isEnableWithdraw: _asBool(json['isEnableWithdraw']) ||
          _asBool(json['is_enable_withdraw']),
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

int? _asTimestamp(dynamic value) {
  if (value == null) {
    return null;
  }

  int timestamp;
  if (value is num) {
    timestamp = value.toInt();
  } else {
    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    final numeric = num.tryParse(text);
    if (numeric != null) {
      timestamp = numeric.toInt();
    } else {
      final parsedDate = DateTime.tryParse(text);
      return parsedDate?.millisecondsSinceEpoch;
    }
  }

  if (timestamp <= 0 || timestamp < 1000000000) {
    return null;
  }

  if (timestamp >= 1000000000000000) {
    timestamp = (timestamp / 1000).round();
  }
  return timestamp;
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
