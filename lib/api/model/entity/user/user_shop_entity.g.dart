// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_shop_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserShopEntityImpl _$$UserShopEntityImplFromJson(Map<String, dynamic> json) =>
    _$UserShopEntityImpl(
      id: json['id'] as String?,
      shopName: json['shopName'] as String?,
      name: json['name'] as String?,
      uuid: json['uuid'] as String?,
      avatar: json['avatar'] as String?,
      openAutoClose: json['openAutoClose'] as bool?,
      isOnline: json['isOnline'] as bool?,
      last7daysAvg: (json['last7daysAvg'] as num?)?.toDouble(),
      last7daysNotSend: (json['last7daysNotSend'] as num?)?.toInt(),
      last7daysNums: (json['last7daysNums'] as num?)?.toInt(),
      last30daysAvg: (json['last30daysAvg'] as num?)?.toDouble(),
      last30daysNotSend: (json['last30daysNotSend'] as num?)?.toInt(),
      last30daysNums: (json['last30daysNums'] as num?)?.toInt(),
      hour: (json['hour'] as num?)?.toInt(),
      minute: (json['minute'] as num?)?.toInt(),
      level: (json['level'] as num?)?.toInt(),
      flag: json['flag'] as bool?,
      sendType: (json['sendType'] as num?)?.toInt(),
      nickname: json['nickname'] as String?,
      signWanted: json['signWanted'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserShopEntityImplToJson(
  _$UserShopEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'shopName': instance.shopName,
  'name': instance.name,
  'uuid': instance.uuid,
  'avatar': instance.avatar,
  'openAutoClose': instance.openAutoClose,
  'isOnline': instance.isOnline,
  'last7daysAvg': instance.last7daysAvg,
  'last7daysNotSend': instance.last7daysNotSend,
  'last7daysNums': instance.last7daysNums,
  'last30daysAvg': instance.last30daysAvg,
  'last30daysNotSend': instance.last30daysNotSend,
  'last30daysNums': instance.last30daysNums,
  'hour': instance.hour,
  'minute': instance.minute,
  'level': instance.level,
  'flag': instance.flag,
  'sendType': instance.sendType,
  'nickname': instance.nickname,
  'signWanted': instance.signWanted,
};
