// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_server_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserServerEntityImpl _$$UserServerEntityImplFromJson(
  Map<String, dynamic> json,
) => _$UserServerEntityImpl(
  allocateTime: json['allocateTime'] as String?,
  applicationDays: json['applicationDays'] as String?,
  createTime: json['createTime'] as String?,
  expireTime: json['expireTime'] as String?,
  flag: json['flag'] as bool?,
  id: json['id'] as String?,
  instanceType: (json['instanceType'] as num?)?.toInt(),
  status: (json['status'] as num?)?.toInt(),
  steamId: json['steamId'] as String?,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$$UserServerEntityImplToJson(
  _$UserServerEntityImpl instance,
) => <String, dynamic>{
  'allocateTime': instance.allocateTime,
  'applicationDays': instance.applicationDays,
  'createTime': instance.createTime,
  'expireTime': instance.expireTime,
  'flag': instance.flag,
  'id': instance.id,
  'instanceType': instance.instanceType,
  'status': instance.status,
  'steamId': instance.steamId,
  'userId': instance.userId,
};
