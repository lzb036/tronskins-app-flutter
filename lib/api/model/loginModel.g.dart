// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loginModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginEntity _$LoginEntityFromJson(Map<String, dynamic> json) => LoginEntity(
  userId: json['userId'] as String?,
  realName: json['realName'] as String?,
  userName: json['userName'] as String?,
  appUse: json['appUse'] as String?,
  desc: json['desc'] as String?,
  initPwdChanged: json['initPwdChanged'] as bool?,
  needSafeToken: json['needSafeToken'] as bool?,
  safeTokenStatus: json['safeTokenStatus'] as bool?,
  token: json['token'] as String?,
  accessToken: json['accessToken'] as String?,
  accessTokenExpireTime: _nullableIntFromJson(json['accessTokenExpireTime']),
  refreshTokenExpireTime: _nullableIntFromJson(json['refreshTokenExpireTime']),
  refreshExpireTime: _nullableIntFromJson(json['refreshExpireTime']),
  header: json['header'] as String?,
  verifyType: _nullableIntFromJson(json['verifyType']),
  authToken: json['authToken'] as String?,
  authType: _nullableIntFromJson(json['authType']),
);

Map<String, dynamic> _$LoginEntityToJson(
  LoginEntity instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'realName': instance.realName,
  'userName': instance.userName,
  'appUse': instance.appUse,
  'desc': instance.desc,
  'initPwdChanged': instance.initPwdChanged,
  'needSafeToken': instance.needSafeToken,
  'safeTokenStatus': instance.safeTokenStatus,
  'token': instance.token,
  'accessToken': instance.accessToken,
  'accessTokenExpireTime': _nullableIntToJson(instance.accessTokenExpireTime),
  'refreshTokenExpireTime': _nullableIntToJson(instance.refreshTokenExpireTime),
  'refreshExpireTime': _nullableIntToJson(instance.refreshExpireTime),
  'header': instance.header,
  'verifyType': _nullableIntToJson(instance.verifyType),
  'authToken': instance.authToken,
  'authType': _nullableIntToJson(instance.authType),
};
