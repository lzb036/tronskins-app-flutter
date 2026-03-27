// lib/api/model/entity/user/user_info_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_fund_entity.dart';
import 'user_json_normalizers.dart';
import 'user_shop_entity.dart';
import 'user_steam_config_entity.dart';
import 'user_server_entity.dart';

part 'user_info_entity.freezed.dart';
part 'user_info_entity.g.dart';

@freezed
class UserInfoEntity with _$UserInfoEntity {
  const factory UserInfoEntity({
    String? id,
    String? uuid,
    String? avatar,
    String? appUse,
    String? account,
    String? nickname,
    String? showEmail,
    bool? need2FA,
    UserShopEntity? shop,
    bool? isBan,
    bool? isBlack,
    UserFundEntity? fund,
    UserSteamConfigEntity? config,
    UserServerEntity? userServer, // 可为 null
    bool? steamTokenUse,
    int? assetTotalNum, // 你接口没返回，默认为0或加字段
    bool? autoManage,
    bool? autoReceive,
    String? banReason,
    String? code,
    bool? commissionFreeUser,
    int? errorCount,
    String? identityId,
    bool? isEnableCommission,
    bool? isManage,
    String? lastIp,
    String? lastLoginTime,
    String? loggerShowName,
    String? loginAddress,
    int? loginMode,
    int? memberLevel,
    int? memberType,
    String? mobile,
    String? note,
    String? realNickname,
    String? registerTime,
    String? safeTokenName,
    bool? safeTokenStatus,
    bool? selfOwned,
    int? sendType,
    bool? flag,
    @Default(false) bool swindle,
    @Default(false) bool vip,
  }) = _UserInfoEntity;

  factory UserInfoEntity.fromJson(Map<String, dynamic> json) =>
      _$UserInfoEntityFromJson(
        normalizeJsonFieldTypes(
          json,
          stringKeys: const <String>[
            'id',
            'uuid',
            'avatar',
            'appUse',
            'account',
            'nickname',
            'showEmail',
            'banReason',
            'code',
            'identityId',
            'lastIp',
            'lastLoginTime',
            'loggerShowName',
            'loginAddress',
            'mobile',
            'note',
            'realNickname',
            'registerTime',
            'safeTokenName',
          ],
          intKeys: const <String>[
            'assetTotalNum',
            'errorCount',
            'loginMode',
            'memberLevel',
            'memberType',
            'sendType',
          ],
          boolKeys: const <String>[
            'need2FA',
            'isBan',
            'isBlack',
            'steamTokenUse',
            'autoManage',
            'autoReceive',
            'commissionFreeUser',
            'isEnableCommission',
            'isManage',
            'safeTokenStatus',
            'selfOwned',
            'flag',
            'swindle',
            'vip',
          ],
        ),
      );
}
