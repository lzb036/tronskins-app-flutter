// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_info_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CurrencyInfoEntityImpl _$$CurrencyInfoEntityImplFromJson(
  Map<String, dynamic> json,
) => _$CurrencyInfoEntityImpl(
  id: (json['id'] as num).toInt(),
  currencyCode: json['currencyCode'] as String,
  rate: (json['rate'] as num).toDouble(),
  createTime: json['createTime'] as String,
  updateTime: json['updateTime'] as String,
);

Map<String, dynamic> _$$CurrencyInfoEntityImplToJson(
  _$CurrencyInfoEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'currencyCode': instance.currencyCode,
  'rate': instance.rate,
  'createTime': instance.createTime,
  'updateTime': instance.updateTime,
};
