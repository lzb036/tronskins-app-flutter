// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_shop_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserShopEntity _$UserShopEntityFromJson(Map<String, dynamic> json) {
  return _UserShopEntity.fromJson(json);
}

/// @nodoc
mixin _$UserShopEntity {
  String? get id => throw _privateConstructorUsedError;
  String? get shopName => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get uuid => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;
  bool? get openAutoClose => throw _privateConstructorUsedError;
  bool? get isOnline => throw _privateConstructorUsedError;
  double? get last7daysAvg => throw _privateConstructorUsedError;
  int? get last7daysNotSend => throw _privateConstructorUsedError;
  int? get last7daysNums => throw _privateConstructorUsedError;
  double? get last30daysAvg => throw _privateConstructorUsedError;
  int? get last30daysNotSend => throw _privateConstructorUsedError;
  int? get last30daysNums => throw _privateConstructorUsedError;
  int? get hour => throw _privateConstructorUsedError;
  int? get minute => throw _privateConstructorUsedError;
  int? get level => throw _privateConstructorUsedError; // 关键！必须可空
  bool? get flag => throw _privateConstructorUsedError;
  int? get sendType => throw _privateConstructorUsedError; // 关键！必须可空
  String? get nickname => throw _privateConstructorUsedError;
  bool get signWanted => throw _privateConstructorUsedError;

  /// Serializes this UserShopEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserShopEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserShopEntityCopyWith<UserShopEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserShopEntityCopyWith<$Res> {
  factory $UserShopEntityCopyWith(
    UserShopEntity value,
    $Res Function(UserShopEntity) then,
  ) = _$UserShopEntityCopyWithImpl<$Res, UserShopEntity>;
  @useResult
  $Res call({
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
    int? level,
    bool? flag,
    int? sendType,
    String? nickname,
    bool signWanted,
  });
}

/// @nodoc
class _$UserShopEntityCopyWithImpl<$Res, $Val extends UserShopEntity>
    implements $UserShopEntityCopyWith<$Res> {
  _$UserShopEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserShopEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? shopName = freezed,
    Object? name = freezed,
    Object? uuid = freezed,
    Object? avatar = freezed,
    Object? openAutoClose = freezed,
    Object? isOnline = freezed,
    Object? last7daysAvg = freezed,
    Object? last7daysNotSend = freezed,
    Object? last7daysNums = freezed,
    Object? last30daysAvg = freezed,
    Object? last30daysNotSend = freezed,
    Object? last30daysNums = freezed,
    Object? hour = freezed,
    Object? minute = freezed,
    Object? level = freezed,
    Object? flag = freezed,
    Object? sendType = freezed,
    Object? nickname = freezed,
    Object? signWanted = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            shopName: freezed == shopName
                ? _value.shopName
                : shopName // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            uuid: freezed == uuid
                ? _value.uuid
                : uuid // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatar: freezed == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                      as String?,
            openAutoClose: freezed == openAutoClose
                ? _value.openAutoClose
                : openAutoClose // ignore: cast_nullable_to_non_nullable
                      as bool?,
            isOnline: freezed == isOnline
                ? _value.isOnline
                : isOnline // ignore: cast_nullable_to_non_nullable
                      as bool?,
            last7daysAvg: freezed == last7daysAvg
                ? _value.last7daysAvg
                : last7daysAvg // ignore: cast_nullable_to_non_nullable
                      as double?,
            last7daysNotSend: freezed == last7daysNotSend
                ? _value.last7daysNotSend
                : last7daysNotSend // ignore: cast_nullable_to_non_nullable
                      as int?,
            last7daysNums: freezed == last7daysNums
                ? _value.last7daysNums
                : last7daysNums // ignore: cast_nullable_to_non_nullable
                      as int?,
            last30daysAvg: freezed == last30daysAvg
                ? _value.last30daysAvg
                : last30daysAvg // ignore: cast_nullable_to_non_nullable
                      as double?,
            last30daysNotSend: freezed == last30daysNotSend
                ? _value.last30daysNotSend
                : last30daysNotSend // ignore: cast_nullable_to_non_nullable
                      as int?,
            last30daysNums: freezed == last30daysNums
                ? _value.last30daysNums
                : last30daysNums // ignore: cast_nullable_to_non_nullable
                      as int?,
            hour: freezed == hour
                ? _value.hour
                : hour // ignore: cast_nullable_to_non_nullable
                      as int?,
            minute: freezed == minute
                ? _value.minute
                : minute // ignore: cast_nullable_to_non_nullable
                      as int?,
            level: freezed == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as int?,
            flag: freezed == flag
                ? _value.flag
                : flag // ignore: cast_nullable_to_non_nullable
                      as bool?,
            sendType: freezed == sendType
                ? _value.sendType
                : sendType // ignore: cast_nullable_to_non_nullable
                      as int?,
            nickname: freezed == nickname
                ? _value.nickname
                : nickname // ignore: cast_nullable_to_non_nullable
                      as String?,
            signWanted: null == signWanted
                ? _value.signWanted
                : signWanted // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserShopEntityImplCopyWith<$Res>
    implements $UserShopEntityCopyWith<$Res> {
  factory _$$UserShopEntityImplCopyWith(
    _$UserShopEntityImpl value,
    $Res Function(_$UserShopEntityImpl) then,
  ) = __$$UserShopEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
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
    int? level,
    bool? flag,
    int? sendType,
    String? nickname,
    bool signWanted,
  });
}

/// @nodoc
class __$$UserShopEntityImplCopyWithImpl<$Res>
    extends _$UserShopEntityCopyWithImpl<$Res, _$UserShopEntityImpl>
    implements _$$UserShopEntityImplCopyWith<$Res> {
  __$$UserShopEntityImplCopyWithImpl(
    _$UserShopEntityImpl _value,
    $Res Function(_$UserShopEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserShopEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? shopName = freezed,
    Object? name = freezed,
    Object? uuid = freezed,
    Object? avatar = freezed,
    Object? openAutoClose = freezed,
    Object? isOnline = freezed,
    Object? last7daysAvg = freezed,
    Object? last7daysNotSend = freezed,
    Object? last7daysNums = freezed,
    Object? last30daysAvg = freezed,
    Object? last30daysNotSend = freezed,
    Object? last30daysNums = freezed,
    Object? hour = freezed,
    Object? minute = freezed,
    Object? level = freezed,
    Object? flag = freezed,
    Object? sendType = freezed,
    Object? nickname = freezed,
    Object? signWanted = null,
  }) {
    return _then(
      _$UserShopEntityImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        shopName: freezed == shopName
            ? _value.shopName
            : shopName // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        uuid: freezed == uuid
            ? _value.uuid
            : uuid // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatar: freezed == avatar
            ? _value.avatar
            : avatar // ignore: cast_nullable_to_non_nullable
                  as String?,
        openAutoClose: freezed == openAutoClose
            ? _value.openAutoClose
            : openAutoClose // ignore: cast_nullable_to_non_nullable
                  as bool?,
        isOnline: freezed == isOnline
            ? _value.isOnline
            : isOnline // ignore: cast_nullable_to_non_nullable
                  as bool?,
        last7daysAvg: freezed == last7daysAvg
            ? _value.last7daysAvg
            : last7daysAvg // ignore: cast_nullable_to_non_nullable
                  as double?,
        last7daysNotSend: freezed == last7daysNotSend
            ? _value.last7daysNotSend
            : last7daysNotSend // ignore: cast_nullable_to_non_nullable
                  as int?,
        last7daysNums: freezed == last7daysNums
            ? _value.last7daysNums
            : last7daysNums // ignore: cast_nullable_to_non_nullable
                  as int?,
        last30daysAvg: freezed == last30daysAvg
            ? _value.last30daysAvg
            : last30daysAvg // ignore: cast_nullable_to_non_nullable
                  as double?,
        last30daysNotSend: freezed == last30daysNotSend
            ? _value.last30daysNotSend
            : last30daysNotSend // ignore: cast_nullable_to_non_nullable
                  as int?,
        last30daysNums: freezed == last30daysNums
            ? _value.last30daysNums
            : last30daysNums // ignore: cast_nullable_to_non_nullable
                  as int?,
        hour: freezed == hour
            ? _value.hour
            : hour // ignore: cast_nullable_to_non_nullable
                  as int?,
        minute: freezed == minute
            ? _value.minute
            : minute // ignore: cast_nullable_to_non_nullable
                  as int?,
        level: freezed == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as int?,
        flag: freezed == flag
            ? _value.flag
            : flag // ignore: cast_nullable_to_non_nullable
                  as bool?,
        sendType: freezed == sendType
            ? _value.sendType
            : sendType // ignore: cast_nullable_to_non_nullable
                  as int?,
        nickname: freezed == nickname
            ? _value.nickname
            : nickname // ignore: cast_nullable_to_non_nullable
                  as String?,
        signWanted: null == signWanted
            ? _value.signWanted
            : signWanted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserShopEntityImpl implements _UserShopEntity {
  const _$UserShopEntityImpl({
    this.id,
    this.shopName,
    this.name,
    this.uuid,
    this.avatar,
    this.openAutoClose,
    this.isOnline,
    this.last7daysAvg,
    this.last7daysNotSend,
    this.last7daysNums,
    this.last30daysAvg,
    this.last30daysNotSend,
    this.last30daysNums,
    this.hour,
    this.minute,
    this.level,
    this.flag,
    this.sendType,
    this.nickname,
    this.signWanted = false,
  });

  factory _$UserShopEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserShopEntityImplFromJson(json);

  @override
  final String? id;
  @override
  final String? shopName;
  @override
  final String? name;
  @override
  final String? uuid;
  @override
  final String? avatar;
  @override
  final bool? openAutoClose;
  @override
  final bool? isOnline;
  @override
  final double? last7daysAvg;
  @override
  final int? last7daysNotSend;
  @override
  final int? last7daysNums;
  @override
  final double? last30daysAvg;
  @override
  final int? last30daysNotSend;
  @override
  final int? last30daysNums;
  @override
  final int? hour;
  @override
  final int? minute;
  @override
  final int? level;
  // 关键！必须可空
  @override
  final bool? flag;
  @override
  final int? sendType;
  // 关键！必须可空
  @override
  final String? nickname;
  @override
  @JsonKey()
  final bool signWanted;

  @override
  String toString() {
    return 'UserShopEntity(id: $id, shopName: $shopName, name: $name, uuid: $uuid, avatar: $avatar, openAutoClose: $openAutoClose, isOnline: $isOnline, last7daysAvg: $last7daysAvg, last7daysNotSend: $last7daysNotSend, last7daysNums: $last7daysNums, last30daysAvg: $last30daysAvg, last30daysNotSend: $last30daysNotSend, last30daysNums: $last30daysNums, hour: $hour, minute: $minute, level: $level, flag: $flag, sendType: $sendType, nickname: $nickname, signWanted: $signWanted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserShopEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.shopName, shopName) ||
                other.shopName == shopName) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.openAutoClose, openAutoClose) ||
                other.openAutoClose == openAutoClose) &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.last7daysAvg, last7daysAvg) ||
                other.last7daysAvg == last7daysAvg) &&
            (identical(other.last7daysNotSend, last7daysNotSend) ||
                other.last7daysNotSend == last7daysNotSend) &&
            (identical(other.last7daysNums, last7daysNums) ||
                other.last7daysNums == last7daysNums) &&
            (identical(other.last30daysAvg, last30daysAvg) ||
                other.last30daysAvg == last30daysAvg) &&
            (identical(other.last30daysNotSend, last30daysNotSend) ||
                other.last30daysNotSend == last30daysNotSend) &&
            (identical(other.last30daysNums, last30daysNums) ||
                other.last30daysNums == last30daysNums) &&
            (identical(other.hour, hour) || other.hour == hour) &&
            (identical(other.minute, minute) || other.minute == minute) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.sendType, sendType) ||
                other.sendType == sendType) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.signWanted, signWanted) ||
                other.signWanted == signWanted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    shopName,
    name,
    uuid,
    avatar,
    openAutoClose,
    isOnline,
    last7daysAvg,
    last7daysNotSend,
    last7daysNums,
    last30daysAvg,
    last30daysNotSend,
    last30daysNums,
    hour,
    minute,
    level,
    flag,
    sendType,
    nickname,
    signWanted,
  ]);

  /// Create a copy of UserShopEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserShopEntityImplCopyWith<_$UserShopEntityImpl> get copyWith =>
      __$$UserShopEntityImplCopyWithImpl<_$UserShopEntityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserShopEntityImplToJson(this);
  }
}

abstract class _UserShopEntity implements UserShopEntity {
  const factory _UserShopEntity({
    final String? id,
    final String? shopName,
    final String? name,
    final String? uuid,
    final String? avatar,
    final bool? openAutoClose,
    final bool? isOnline,
    final double? last7daysAvg,
    final int? last7daysNotSend,
    final int? last7daysNums,
    final double? last30daysAvg,
    final int? last30daysNotSend,
    final int? last30daysNums,
    final int? hour,
    final int? minute,
    final int? level,
    final bool? flag,
    final int? sendType,
    final String? nickname,
    final bool signWanted,
  }) = _$UserShopEntityImpl;

  factory _UserShopEntity.fromJson(Map<String, dynamic> json) =
      _$UserShopEntityImpl.fromJson;

  @override
  String? get id;
  @override
  String? get shopName;
  @override
  String? get name;
  @override
  String? get uuid;
  @override
  String? get avatar;
  @override
  bool? get openAutoClose;
  @override
  bool? get isOnline;
  @override
  double? get last7daysAvg;
  @override
  int? get last7daysNotSend;
  @override
  int? get last7daysNums;
  @override
  double? get last30daysAvg;
  @override
  int? get last30daysNotSend;
  @override
  int? get last30daysNums;
  @override
  int? get hour;
  @override
  int? get minute;
  @override
  int? get level; // 关键！必须可空
  @override
  bool? get flag;
  @override
  int? get sendType; // 关键！必须可空
  @override
  String? get nickname;
  @override
  bool get signWanted;

  /// Create a copy of UserShopEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserShopEntityImplCopyWith<_$UserShopEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
