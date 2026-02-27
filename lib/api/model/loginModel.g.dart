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
  verifyType: (json['verifyType'] as num?)?.toInt(),
  authToken: json['authToken'] as String?,
  authType: (json['authType'] as num?)?.toInt(),
);

Map<String, dynamic> _$LoginEntityToJson(LoginEntity instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'realName': instance.realName,
      'userName': instance.userName,
      'appUse': instance.appUse,
      'desc': instance.desc,
      'initPwdChanged': instance.initPwdChanged,
      'needSafeToken': instance.needSafeToken,
      'safeTokenStatus': instance.safeTokenStatus,
      'token': instance.token,
      'verifyType': instance.verifyType,
      'authToken': instance.authToken,
      'authType': instance.authType,
    };
