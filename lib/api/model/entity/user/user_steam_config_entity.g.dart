// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_steam_config_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSteamConfigEntityImpl _$$UserSteamConfigEntityImplFromJson(
  Map<String, dynamic> json,
) => _$UserSteamConfigEntityImpl(
  id: json['id'] as String?,
  avatar: json['avatar'] as String?,
  createTime: json['createTime'] as String?,
  lastLoginTime: json['lastLoginTime'] as String?,
  level: (json['level'] as num?)?.toInt(),
  logged: json['logged'] as bool?,
  loginType: (json['loginType'] as num?)?.toInt(),
  nickname: json['nickname'] as String?,
  partnerId: json['partnerId'] as String?,
  privacy: json['privacy'] as bool?,
  sensitiveAccessKey: json['sensitiveAccessKey'] as String?,
  steamId: json['steamId'] as String?,
  tradableTime: json['tradableTime'] as String?,
  tradeStatus: json['tradeStatus'] as bool?,
  tradeUrl: json['tradeUrl'] as String?,
  tradeUrlStatus: json['tradeUrlStatus'] as bool?,
  uuid: json['uuid'] as String?,
  yearsLevel: (json['yearsLevel'] as num?)?.toInt(),
  flag: json['flag'] as bool?,
);

Map<String, dynamic> _$$UserSteamConfigEntityImplToJson(
  _$UserSteamConfigEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'avatar': instance.avatar,
  'createTime': instance.createTime,
  'lastLoginTime': instance.lastLoginTime,
  'level': instance.level,
  'logged': instance.logged,
  'loginType': instance.loginType,
  'nickname': instance.nickname,
  'partnerId': instance.partnerId,
  'privacy': instance.privacy,
  'sensitiveAccessKey': instance.sensitiveAccessKey,
  'steamId': instance.steamId,
  'tradableTime': instance.tradableTime,
  'tradeStatus': instance.tradeStatus,
  'tradeUrl': instance.tradeUrl,
  'tradeUrlStatus': instance.tradeUrlStatus,
  'uuid': instance.uuid,
  'yearsLevel': instance.yearsLevel,
  'flag': instance.flag,
};
