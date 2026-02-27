// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_fund_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserFundEntityImpl _$$UserFundEntityImplFromJson(Map<String, dynamic> json) =>
    _$UserFundEntityImpl(
      id: json['id'] as String?,
      available: (json['available'] as num?)?.toDouble(),
      balance: (json['balance'] as num?)?.toDouble(),
      gift: (json['gift'] as num?)?.toDouble(),
      integral: json['integral'] as String?,
      locked: (json['locked'] as num?)?.toDouble(),
      settlement: (json['settlement'] as num?)?.toDouble(),
      flag: json['flag'] as bool?,
      deposit: (json['deposit'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$UserFundEntityImplToJson(
  _$UserFundEntityImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'available': instance.available,
  'balance': instance.balance,
  'gift': instance.gift,
  'integral': instance.integral,
  'locked': instance.locked,
  'settlement': instance.settlement,
  'flag': instance.flag,
  'deposit': instance.deposit,
};
