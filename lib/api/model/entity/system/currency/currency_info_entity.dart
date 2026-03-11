import 'package:freezed_annotation/freezed_annotation.dart';
part 'currency_info_entity.freezed.dart';
part 'currency_info_entity.g.dart';

@freezed
class CurrencyInfoEntity with _$CurrencyInfoEntity {
  const factory CurrencyInfoEntity({
    required int id,
    required String currencyCode,
    required double rate,
    required String createTime,
    required String updateTime,
  }) = _CurrencyInfoEntity;

  factory CurrencyInfoEntity.fromJson(Map<String, dynamic> json) =>
      _$CurrencyInfoEntityFromJson(json);
}
