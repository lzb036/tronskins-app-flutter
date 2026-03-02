// ignore_for_file: file_names

import 'package:json_annotation/json_annotation.dart';
part 'loginModel.g.dart';

int? _nullableIntFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

dynamic _nullableIntToJson(int? value) => value;

@JsonSerializable(explicitToJson: true)
class LoginEntity {
  /// 用户id
  @JsonKey(name: 'userId')
  final String? userId;

  /// 名称
  @JsonKey(name: 'realName')
  final String? realName;

  /// 用户名
  @JsonKey(name: 'userName')
  final String? userName;

  /// 节点（你原来注释是“节点”，实际字段名可能是 appUse 或其他）
  @JsonKey(name: 'appUse')
  final String? appUse;

  /// 提示信息
  @JsonKey(name: 'desc')
  final String? desc;

  /// 初始密码是否修改过
  @JsonKey(name: 'initPwdChanged')
  final bool? initPwdChanged;

  /// 是否需要安全令牌
  @JsonKey(name: 'needSafeToken')
  final bool? needSafeToken;

  /// 令牌验证方式（实际含义请根据接口文档确认）
  @JsonKey(name: 'safeTokenStatus')
  final bool? safeTokenStatus;

  /// JWT 或其他登录令牌
  @JsonKey(name: 'token')
  final String? token;

  /// 双 token 中的 access token（优先于 token）
  @JsonKey(name: 'accessToken')
  final String? accessToken;

  /// access token 过期时间（毫秒时间戳）
  @JsonKey(
    name: 'accessTokenExpireTime',
    fromJson: _nullableIntFromJson,
    toJson: _nullableIntToJson,
  )
  final int? accessTokenExpireTime;

  /// refresh token 过期时间（毫秒时间戳）
  @JsonKey(
    name: 'refreshTokenExpireTime',
    fromJson: _nullableIntFromJson,
    toJson: _nullableIntToJson,
  )
  final int? refreshTokenExpireTime;

  /// refresh token 过期时间兼容字段（毫秒时间戳）
  @JsonKey(
    name: 'refreshExpireTime',
    fromJson: _nullableIntFromJson,
    toJson: _nullableIntToJson,
  )
  final int? refreshExpireTime;

  /// 动态认证头（兼容后端扩展字段）
  @JsonKey(name: 'header')
  final String? header;

  /// 登录验证类型 0:无需验证 1:邮箱 2:2FA
  @JsonKey(
    name: 'verifyType',
    fromJson: _nullableIntFromJson,
    toJson: _nullableIntToJson,
  )
  final int? verifyType;

  /// 验证用 authToken
  @JsonKey(name: 'authToken')
  final String? authToken;

  /// 认证方式 1: 邮箱验证 等
  @JsonKey(
    name: 'authType',
    fromJson: _nullableIntFromJson,
    toJson: _nullableIntToJson,
  )
  final int? authType;

  // 必须提供构造函数（带所有字段）
  const LoginEntity({
    required this.userId,
    required this.realName,
    required this.userName,
    required this.appUse,
    required this.desc,
    required this.initPwdChanged,
    required this.needSafeToken,
    required this.safeTokenStatus,
    required this.token,
    required this.accessToken,
    required this.accessTokenExpireTime,
    required this.refreshTokenExpireTime,
    required this.refreshExpireTime,
    required this.header,
    required this.verifyType,
    required this.authToken,
    required this.authType,
  });

  String? get effectiveAccessToken {
    if (accessToken != null && accessToken!.isNotEmpty) {
      return accessToken;
    }
    if (token != null && token!.isNotEmpty) {
      return token;
    }
    return null;
  }

  int? get effectiveRefreshTokenExpireTime =>
      refreshTokenExpireTime ?? refreshExpireTime;

  // json_serializable 必须的两个方法
  factory LoginEntity.fromJson(Map<String, dynamic> json) =>
      _$LoginEntityFromJson(json);

  Map<String, dynamic> toJson() => _$LoginEntityToJson(this);
}
