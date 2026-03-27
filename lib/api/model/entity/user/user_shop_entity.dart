// lib/api/model/entity/user/user_shop_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_json_normalizers.dart';

part 'user_shop_entity.freezed.dart';
part 'user_shop_entity.g.dart';

@freezed
class UserShopEntity with _$UserShopEntity {
  const factory UserShopEntity({
    String? id,
    String? shopName,
    String? name,
    String? uuid,
    String? avatar,
    bool? openAutoClose,
    bool? isOnline,
    double? last7daysAvg,
    int? last7daysNotSend,
    int? last7daysNums,
    double? last30daysAvg,
    int? last30daysNotSend,
    int? last30daysNums,
    int? hour,
    int? minute,
    int? level, // 关键！必须可空
    bool? flag,
    int? sendType, // 关键！必须可空
    String? nickname,
    @Default(false) bool signWanted,
  }) = _UserShopEntity;

  factory UserShopEntity.fromJson(Map<String, dynamic> json) =>
      _$UserShopEntityFromJson(
        normalizeJsonFieldTypes(
          json,
          stringKeys: const <String>[
            'id',
            'shopName',
            'name',
            'uuid',
            'avatar',
            'nickname',
          ],
          intKeys: const <String>[
            'last7daysNotSend',
            'last7daysNums',
            'last30daysNotSend',
            'last30daysNums',
            'hour',
            'minute',
            'level',
            'sendType',
          ],
          doubleKeys: const <String>['last7daysAvg', 'last30daysAvg'],
          boolKeys: const <String>[
            'openAutoClose',
            'isOnline',
            'flag',
            'signWanted',
          ],
        ),
      );
}
