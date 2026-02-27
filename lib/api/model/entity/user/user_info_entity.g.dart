// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserInfoEntityImpl _$$UserInfoEntityImplFromJson(
  Map<String, dynamic> json,
) => _$UserInfoEntityImpl(
  id: json['id'] as String?,
  uuid: json['uuid'] as String?,
  avatar: json['avatar'] as String?,
  appUse: json['appUse'] as String?,
  account: json['account'] as String?,
  nickname: json['nickname'] as String?,
  showEmail: json['showEmail'] as String?,
  need2FA: json['need2FA'] as bool?,
  shop: json['shop'] == null
      ? null
      : UserShopEntity.fromJson(json['shop'] as Map<String, dynamic>),
  isBan: json['isBan'] as bool?,
  isBlack: json['isBlack'] as bool?,
  fund: json['fund'] == null
      ? null
      : UserFundEntity.fromJson(json['fund'] as Map<String, dynamic>),
  config: json['config'] == null
      ? null
      : UserSteamConfigEntity.fromJson(json['config'] as Map<String, dynamic>),
  userServer: json['userServer'] == null
      ? null
      : UserServerEntity.fromJson(json['userServer'] as Map<String, dynamic>),
  steamTokenUse: json['steamTokenUse'] as bool?,
  assetTotalNum: (json['assetTotalNum'] as num?)?.toInt(),
  autoManage: json['autoManage'] as bool?,
  autoReceive: json['autoReceive'] as bool?,
  banReason: json['banReason'] as String?,
  code: json['code'] as String?,
  commissionFreeUser: json['commissionFreeUser'] as bool?,
  errorCount: (json['errorCount'] as num?)?.toInt(),
  identityId: json['identityId'] as String?,
  isEnableCommission: json['isEnableCommission'] as bool?,
  isManage: json['isManage'] as bool?,
  lastIp: json['lastIp'] as String?,
  lastLoginTime: json['lastLoginTime'] as String?,
  loggerShowName: json['loggerShowName'] as String?,
  loginAddress: json['loginAddress'] as String?,
  loginMode: (json['loginMode'] as num?)?.toInt(),
  memberLevel: (json['memberLevel'] as num?)?.toInt(),
  memberType: (json['memberType'] as num?)?.toInt(),
  mobile: json['mobile'] as String?,
  note: json['note'] as String?,
  realNickname: json['realNickname'] as String?,
  registerTime: json['registerTime'] as String?,
  safeTokenName: json['safeTokenName'] as String?,
  safeTokenStatus: json['safeTokenStatus'] as bool?,
  selfOwned: json['selfOwned'] as bool?,
  sendType: (json['sendType'] as num?)?.toInt(),
  flag: json['flag'] as bool?,
  swindle: json['swindle'] as bool? ?? false,
  vip: json['vip'] as bool? ?? false,
);

Map<String, dynamic> _$$UserInfoEntityImplToJson(
  _$UserInfoEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'uuid': instance.uuid,
  'avatar': instance.avatar,
  'appUse': instance.appUse,
  'account': instance.account,
  'nickname': instance.nickname,
  'showEmail': instance.showEmail,
  'need2FA': instance.need2FA,
  'shop': instance.shop,
  'isBan': instance.isBan,
  'isBlack': instance.isBlack,
  'fund': instance.fund,
  'config': instance.config,
  'userServer': instance.userServer,
  'steamTokenUse': instance.steamTokenUse,
  'assetTotalNum': instance.assetTotalNum,
  'autoManage': instance.autoManage,
  'autoReceive': instance.autoReceive,
  'banReason': instance.banReason,
  'code': instance.code,
  'commissionFreeUser': instance.commissionFreeUser,
  'errorCount': instance.errorCount,
  'identityId': instance.identityId,
  'isEnableCommission': instance.isEnableCommission,
  'isManage': instance.isManage,
  'lastIp': instance.lastIp,
  'lastLoginTime': instance.lastLoginTime,
  'loggerShowName': instance.loggerShowName,
  'loginAddress': instance.loginAddress,
  'loginMode': instance.loginMode,
  'memberLevel': instance.memberLevel,
  'memberType': instance.memberType,
  'mobile': instance.mobile,
  'note': instance.note,
  'realNickname': instance.realNickname,
  'registerTime': instance.registerTime,
  'safeTokenName': instance.safeTokenName,
  'safeTokenStatus': instance.safeTokenStatus,
  'selfOwned': instance.selfOwned,
  'sendType': instance.sendType,
  'flag': instance.flag,
  'swindle': instance.swindle,
  'vip': instance.vip,
};
