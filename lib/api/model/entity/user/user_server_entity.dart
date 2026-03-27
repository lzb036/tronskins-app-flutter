// lib/api/model/entity/user/user_server_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_json_normalizers.dart';

part 'user_server_entity.freezed.dart';
part 'user_server_entity.g.dart';

@freezed
class UserServerEntity with _$UserServerEntity {
  const factory UserServerEntity({
    String? allocateTime,
    String? applicationDays,
    String? createTime,
    String? expireTime,
    bool? flag,
    String? id,
    int? instanceType,
    int? status,
    String? steamId,
    String? userId,
  }) = _UserServerEntity;

  factory UserServerEntity.fromJson(Map<String, dynamic> json) =>
      _$UserServerEntityFromJson(
        normalizeJsonFieldTypes(
          json,
          stringKeys: const <String>[
            'allocateTime',
            'applicationDays',
            'createTime',
            'expireTime',
            'id',
            'steamId',
            'userId',
          ],
          intKeys: const <String>['instanceType', 'status'],
          boolKeys: const <String>['flag'],
        ),
      );
}
