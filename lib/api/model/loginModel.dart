// ignore_for_file: file_names

import 'package:json_annotation/json_annotation.dart';
part 'loginModel.g.dart';

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

  /// 登录验证类型 0:无需验证 1:邮箱 2:2FA
  @JsonKey(name: 'verifyType')
  final int? verifyType;

  /// 验证用 authToken
  @JsonKey(name: 'authToken')
  final String? authToken;

  /// 认证方式 1: 邮箱验证 等
  @JsonKey(name: 'authType')
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
    required this.verifyType,
    required this.authToken,
    required this.authType,
  });

  // json_serializable 必须的两个方法
  factory LoginEntity.fromJson(Map<String, dynamic> json) =>
      _$LoginEntityFromJson(json);

  Map<String, dynamic> toJson() => _$LoginEntityToJson(this);
}
