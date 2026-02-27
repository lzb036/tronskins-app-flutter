// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'currency_info_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CurrencyInfoEntity _$CurrencyInfoEntityFromJson(Map<String, dynamic> json) {
  return _CurrencyInfoEntity.fromJson(json);
}

/// @nodoc
mixin _$CurrencyInfoEntity {
  int get id => throw _privateConstructorUsedError;
  String get currencyCode => throw _privateConstructorUsedError;
  double get rate => throw _privateConstructorUsedError;
  String get createTime => throw _privateConstructorUsedError;
  String get updateTime => throw _privateConstructorUsedError;

  /// Serializes this CurrencyInfoEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CurrencyInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CurrencyInfoEntityCopyWith<CurrencyInfoEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CurrencyInfoEntityCopyWith<$Res> {
  factory $CurrencyInfoEntityCopyWith(
    CurrencyInfoEntity value,
    $Res Function(CurrencyInfoEntity) then,
  ) = _$CurrencyInfoEntityCopyWithImpl<$Res, CurrencyInfoEntity>;
  @useResult
  $Res call({
    int id,
    String currencyCode,
    double rate,
    String createTime,
    String updateTime,
  });
}

/// @nodoc
class _$CurrencyInfoEntityCopyWithImpl<$Res, $Val extends CurrencyInfoEntity>
    implements $CurrencyInfoEntityCopyWith<$Res> {
  _$CurrencyInfoEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CurrencyInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? currencyCode = null,
    Object? rate = null,
    Object? createTime = null,
    Object? updateTime = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            currencyCode: null == currencyCode
                ? _value.currencyCode
                : currencyCode // ignore: cast_nullable_to_non_nullable
                      as String,
            rate: null == rate
                ? _value.rate
                : rate // ignore: cast_nullable_to_non_nullable
                      as double,
            createTime: null == createTime
                ? _value.createTime
                : createTime // ignore: cast_nullable_to_non_nullable
                      as String,
            updateTime: null == updateTime
                ? _value.updateTime
                : updateTime // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CurrencyInfoEntityImplCopyWith<$Res>
    implements $CurrencyInfoEntityCopyWith<$Res> {
  factory _$$CurrencyInfoEntityImplCopyWith(
    _$CurrencyInfoEntityImpl value,
    $Res Function(_$CurrencyInfoEntityImpl) then,
  ) = __$$CurrencyInfoEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String currencyCode,
    double rate,
    String createTime,
    String updateTime,
  });
}

/// @nodoc
class __$$CurrencyInfoEntityImplCopyWithImpl<$Res>
    extends _$CurrencyInfoEntityCopyWithImpl<$Res, _$CurrencyInfoEntityImpl>
    implements _$$CurrencyInfoEntityImplCopyWith<$Res> {
  __$$CurrencyInfoEntityImplCopyWithImpl(
    _$CurrencyInfoEntityImpl _value,
    $Res Function(_$CurrencyInfoEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CurrencyInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? currencyCode = null,
    Object? rate = null,
    Object? createTime = null,
    Object? updateTime = null,
  }) {
    return _then(
      _$CurrencyInfoEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        currencyCode: null == currencyCode
            ? _value.currencyCode
            : currencyCode // ignore: cast_nullable_to_non_nullable
                  as String,
        rate: null == rate
            ? _value.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as double,
        createTime: null == createTime
            ? _value.createTime
            : createTime // ignore: cast_nullable_to_non_nullable
                  as String,
        updateTime: null == updateTime
            ? _value.updateTime
            : updateTime // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CurrencyInfoEntityImpl implements _CurrencyInfoEntity {
  const _$CurrencyInfoEntityImpl({
    required this.id,
    required this.currencyCode,
    required this.rate,
    required this.createTime,
    required this.updateTime,
  });

  factory _$CurrencyInfoEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$CurrencyInfoEntityImplFromJson(json);

  @override
  final int id;
  @override
  final String currencyCode;
  @override
  final double rate;
  @override
  final String createTime;
  @override
  final String updateTime;

  @override
  String toString() {
    return 'CurrencyInfoEntity(id: $id, currencyCode: $currencyCode, rate: $rate, createTime: $createTime, updateTime: $updateTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CurrencyInfoEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, currencyCode, rate, createTime, updateTime);

  /// Create a copy of CurrencyInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CurrencyInfoEntityImplCopyWith<_$CurrencyInfoEntityImpl> get copyWith =>
      __$$CurrencyInfoEntityImplCopyWithImpl<_$CurrencyInfoEntityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CurrencyInfoEntityImplToJson(this);
  }
}

abstract class _CurrencyInfoEntity implements CurrencyInfoEntity {
  const factory _CurrencyInfoEntity({
    required final int id,
    required final String currencyCode,
    required final double rate,
    required final String createTime,
    required final String updateTime,
  }) = _$CurrencyInfoEntityImpl;

  factory _CurrencyInfoEntity.fromJson(Map<String, dynamic> json) =
      _$CurrencyInfoEntityImpl.fromJson;

  @override
  int get id;
  @override
  String get currencyCode;
  @override
  double get rate;
  @override
  String get createTime;
  @override
  String get updateTime;

  /// Create a copy of CurrencyInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CurrencyInfoEntityImplCopyWith<_$CurrencyInfoEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
