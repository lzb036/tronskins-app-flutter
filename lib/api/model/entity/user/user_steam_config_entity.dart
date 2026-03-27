// lib/api/model/entity/user/user_steam_config_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_json_normalizers.dart';

part 'user_steam_config_entity.freezed.dart';
part 'user_steam_config_entity.g.dart';

@freezed
class UserSteamConfigEntity with _$UserSteamConfigEntity {
  const factory UserSteamConfigEntity({
    String? id,
    String? avatar,
    String? createTime,
    String? lastLoginTime,
    int? level,
    bool? logged,
    int? loginType,
    String? nickname,
    String? partnerId,
    bool? privacy,
    String? sensitiveAccessKey,
    String? steamId,
    String? tradableTime,
    bool? tradeStatus,
    String? tradeUrl,
    bool? tradeUrlStatus,
    String? uuid,
    int? yearsLevel,
    bool? flag,
  }) = _UserSteamConfigEntity;

  factory UserSteamConfigEntity.fromJson(Map<String, dynamic> json) =>
      _$UserSteamConfigEntityFromJson(
        normalizeJsonFieldTypes(
          json,
          stringKeys: const <String>[
            'id',
            'avatar',
            'createTime',
            'lastLoginTime',
            'nickname',
            'partnerId',
            'sensitiveAccessKey',
            'steamId',
            'tradableTime',
            'tradeUrl',
            'uuid',
          ],
          intKeys: const <String>['level', 'loginType', 'yearsLevel'],
          boolKeys: const <String>[
            'logged',
            'privacy',
            'tradeStatus',
            'tradeUrlStatus',
            'flag',
          ],
        ),
      );
}
