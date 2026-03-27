// lib/api/model/entity/user/user_fund_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_json_normalizers.dart';

part 'user_fund_entity.freezed.dart';
part 'user_fund_entity.g.dart';

@freezed
class UserFundEntity with _$UserFundEntity {
  const factory UserFundEntity({
    String? id,
    double? available,
    double? balance,
    double? gift,
    String? integral,
    double? locked,
    double? settlement,
    bool? flag,
    double? deposit,
  }) = _UserFundEntity;

  factory UserFundEntity.fromJson(Map<String, dynamic> json) =>
      _$UserFundEntityFromJson(
        normalizeJsonFieldTypes(
          json,
          stringKeys: const <String>['id', 'integral'],
          doubleKeys: const <String>[
            'available',
            'balance',
            'gift',
            'locked',
            'settlement',
            'deposit',
          ],
          boolKeys: const <String>['flag'],
        ),
      );
}
