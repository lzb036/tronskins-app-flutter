// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_info_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserInfoEntity _$UserInfoEntityFromJson(Map<String, dynamic> json) {
  return _UserInfoEntity.fromJson(json);
}

/// @nodoc
mixin _$UserInfoEntity {
  String? get id => throw _privateConstructorUsedError;
  String? get uuid => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;
  String? get appUse => throw _privateConstructorUsedError;
  String? get account => throw _privateConstructorUsedError;
  String? get nickname => throw _privateConstructorUsedError;
  String? get showEmail => throw _privateConstructorUsedError;
  bool? get need2FA => throw _privateConstructorUsedError;
  UserShopEntity? get shop => throw _privateConstructorUsedError;
  bool? get isBan => throw _privateConstructorUsedError;
  bool? get isBlack => throw _privateConstructorUsedError;
  UserFundEntity? get fund => throw _privateConstructorUsedError;
  UserSteamConfigEntity? get config => throw _privateConstructorUsedError;
  UserServerEntity? get userServer =>
      throw _privateConstructorUsedError; // 可为 null
  bool? get steamTokenUse => throw _privateConstructorUsedError;
  int? get assetTotalNum =>
      throw _privateConstructorUsedError; // 你接口没返回，默认为0或加字段
  bool? get autoManage => throw _privateConstructorUsedError;
  bool? get autoReceive => throw _privateConstructorUsedError;
  String? get banReason => throw _privateConstructorUsedError;
  String? get code => throw _privateConstructorUsedError;
  bool? get commissionFreeUser => throw _privateConstructorUsedError;
  int? get errorCount => throw _privateConstructorUsedError;
  String? get identityId => throw _privateConstructorUsedError;
  bool? get isEnableCommission => throw _privateConstructorUsedError;
  bool? get isManage => throw _privateConstructorUsedError;
  String? get lastIp => throw _privateConstructorUsedError;
  String? get lastLoginTime => throw _privateConstructorUsedError;
  String? get loggerShowName => throw _privateConstructorUsedError;
  String? get loginAddress => throw _privateConstructorUsedError;
  int? get loginMode => throw _privateConstructorUsedError;
  int? get memberLevel => throw _privateConstructorUsedError;
  int? get memberType => throw _privateConstructorUsedError;
  String? get mobile => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  String? get realNickname => throw _privateConstructorUsedError;
  String? get registerTime => throw _privateConstructorUsedError;
  String? get safeTokenName => throw _privateConstructorUsedError;
  bool? get safeTokenStatus => throw _privateConstructorUsedError;
  bool? get selfOwned => throw _privateConstructorUsedError;
  int? get sendType => throw _privateConstructorUsedError;
  bool? get flag => throw _privateConstructorUsedError;
  bool get swindle => throw _privateConstructorUsedError;
  bool get vip => throw _privateConstructorUsedError;

  /// Serializes this UserInfoEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserInfoEntityCopyWith<UserInfoEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserInfoEntityCopyWith<$Res> {
  factory $UserInfoEntityCopyWith(
    UserInfoEntity value,
    $Res Function(UserInfoEntity) then,
  ) = _$UserInfoEntityCopyWithImpl<$Res, UserInfoEntity>;
  @useResult
  $Res call({
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
    UserServerEntity? userServer,
    bool? steamTokenUse,
    int? assetTotalNum,
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
    bool swindle,
    bool vip,
  });

  $UserShopEntityCopyWith<$Res>? get shop;
  $UserFundEntityCopyWith<$Res>? get fund;
  $UserSteamConfigEntityCopyWith<$Res>? get config;
  $UserServerEntityCopyWith<$Res>? get userServer;
}

/// @nodoc
class _$UserInfoEntityCopyWithImpl<$Res, $Val extends UserInfoEntity>
    implements $UserInfoEntityCopyWith<$Res> {
  _$UserInfoEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? uuid = freezed,
    Object? avatar = freezed,
    Object? appUse = freezed,
    Object? account = freezed,
    Object? nickname = freezed,
    Object? showEmail = freezed,
    Object? need2FA = freezed,
    Object? shop = freezed,
    Object? isBan = freezed,
    Object? isBlack = freezed,
    Object? fund = freezed,
    Object? config = freezed,
    Object? userServer = freezed,
    Object? steamTokenUse = freezed,
    Object? assetTotalNum = freezed,
    Object? autoManage = freezed,
    Object? autoReceive = freezed,
    Object? banReason = freezed,
    Object? code = freezed,
    Object? commissionFreeUser = freezed,
    Object? errorCount = freezed,
    Object? identityId = freezed,
    Object? isEnableCommission = freezed,
    Object? isManage = freezed,
    Object? lastIp = freezed,
    Object? lastLoginTime = freezed,
    Object? loggerShowName = freezed,
    Object? loginAddress = freezed,
    Object? loginMode = freezed,
    Object? memberLevel = freezed,
    Object? memberType = freezed,
    Object? mobile = freezed,
    Object? note = freezed,
    Object? realNickname = freezed,
    Object? registerTime = freezed,
    Object? safeTokenName = freezed,
    Object? safeTokenStatus = freezed,
    Object? selfOwned = freezed,
    Object? sendType = freezed,
    Object? flag = freezed,
    Object? swindle = null,
    Object? vip = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            uuid: freezed == uuid
                ? _value.uuid
                : uuid // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatar: freezed == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                      as String?,
            appUse: freezed == appUse
                ? _value.appUse
                : appUse // ignore: cast_nullable_to_non_nullable
                      as String?,
            account: freezed == account
                ? _value.account
                : account // ignore: cast_nullable_to_non_nullable
                      as String?,
            nickname: freezed == nickname
                ? _value.nickname
                : nickname // ignore: cast_nullable_to_non_nullable
                      as String?,
            showEmail: freezed == showEmail
                ? _value.showEmail
                : showEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            need2FA: freezed == need2FA
                ? _value.need2FA
                : need2FA // ignore: cast_nullable_to_non_nullable
                      as bool?,
            shop: freezed == shop
                ? _value.shop
                : shop // ignore: cast_nullable_to_non_nullable
                      as UserShopEntity?,
            isBan: freezed == isBan
                ? _value.isBan
                : isBan // ignore: cast_nullable_to_non_nullable
                      as bool?,
            isBlack: freezed == isBlack
                ? _value.isBlack
                : isBlack // ignore: cast_nullable_to_non_nullable
                      as bool?,
            fund: freezed == fund
                ? _value.fund
                : fund // ignore: cast_nullable_to_non_nullable
                      as UserFundEntity?,
            config: freezed == config
                ? _value.config
                : config // ignore: cast_nullable_to_non_nullable
                      as UserSteamConfigEntity?,
            userServer: freezed == userServer
                ? _value.userServer
                : userServer // ignore: cast_nullable_to_non_nullable
                      as UserServerEntity?,
            steamTokenUse: freezed == steamTokenUse
                ? _value.steamTokenUse
                : steamTokenUse // ignore: cast_nullable_to_non_nullable
                      as bool?,
            assetTotalNum: freezed == assetTotalNum
                ? _value.assetTotalNum
                : assetTotalNum // ignore: cast_nullable_to_non_nullable
                      as int?,
            autoManage: freezed == autoManage
                ? _value.autoManage
                : autoManage // ignore: cast_nullable_to_non_nullable
                      as bool?,
            autoReceive: freezed == autoReceive
                ? _value.autoReceive
                : autoReceive // ignore: cast_nullable_to_non_nullable
                      as bool?,
            banReason: freezed == banReason
                ? _value.banReason
                : banReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            code: freezed == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String?,
            commissionFreeUser: freezed == commissionFreeUser
                ? _value.commissionFreeUser
                : commissionFreeUser // ignore: cast_nullable_to_non_nullable
                      as bool?,
            errorCount: freezed == errorCount
                ? _value.errorCount
                : errorCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            identityId: freezed == identityId
                ? _value.identityId
                : identityId // ignore: cast_nullable_to_non_nullable
                      as String?,
            isEnableCommission: freezed == isEnableCommission
                ? _value.isEnableCommission
                : isEnableCommission // ignore: cast_nullable_to_non_nullable
                      as bool?,
            isManage: freezed == isManage
                ? _value.isManage
                : isManage // ignore: cast_nullable_to_non_nullable
                      as bool?,
            lastIp: freezed == lastIp
                ? _value.lastIp
                : lastIp // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastLoginTime: freezed == lastLoginTime
                ? _value.lastLoginTime
                : lastLoginTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            loggerShowName: freezed == loggerShowName
                ? _value.loggerShowName
                : loggerShowName // ignore: cast_nullable_to_non_nullable
                      as String?,
            loginAddress: freezed == loginAddress
                ? _value.loginAddress
                : loginAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            loginMode: freezed == loginMode
                ? _value.loginMode
                : loginMode // ignore: cast_nullable_to_non_nullable
                      as int?,
            memberLevel: freezed == memberLevel
                ? _value.memberLevel
                : memberLevel // ignore: cast_nullable_to_non_nullable
                      as int?,
            memberType: freezed == memberType
                ? _value.memberType
                : memberType // ignore: cast_nullable_to_non_nullable
                      as int?,
            mobile: freezed == mobile
                ? _value.mobile
                : mobile // ignore: cast_nullable_to_non_nullable
                      as String?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            realNickname: freezed == realNickname
                ? _value.realNickname
                : realNickname // ignore: cast_nullable_to_non_nullable
                      as String?,
            registerTime: freezed == registerTime
                ? _value.registerTime
                : registerTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            safeTokenName: freezed == safeTokenName
                ? _value.safeTokenName
                : safeTokenName // ignore: cast_nullable_to_non_nullable
                      as String?,
            safeTokenStatus: freezed == safeTokenStatus
                ? _value.safeTokenStatus
                : safeTokenStatus // ignore: cast_nullable_to_non_nullable
                      as bool?,
            selfOwned: freezed == selfOwned
                ? _value.selfOwned
                : selfOwned // ignore: cast_nullable_to_non_nullable
                      as bool?,
            sendType: freezed == sendType
                ? _value.sendType
                : sendType // ignore: cast_nullable_to_non_nullable
                      as int?,
            flag: freezed == flag
                ? _value.flag
                : flag // ignore: cast_nullable_to_non_nullable
                      as bool?,
            swindle: null == swindle
                ? _value.swindle
                : swindle // ignore: cast_nullable_to_non_nullable
                      as bool,
            vip: null == vip
                ? _value.vip
                : vip // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of UserInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserShopEntityCopyWith<$Res>? get shop {
    if (_value.shop == null) {
      return null;
    }

    return $UserShopEntityCopyWith<$Res>(_value.shop!, (value) {
      return _then(_value.copyWith(shop: value) as $Val);
    });
  }

  /// Create a copy of UserInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserFundEntityCopyWith<$Res>? get fund {
    if (_value.fund == null) {
      return null;
    }

    return $UserFundEntityCopyWith<$Res>(_value.fund!, (value) {
      return _then(_value.copyWith(fund: value) as $Val);
    });
  }

  /// Create a copy of UserInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserSteamConfigEntityCopyWith<$Res>? get config {
    if (_value.config == null) {
      return null;
    }

    return $UserSteamConfigEntityCopyWith<$Res>(_value.config!, (value) {
      return _then(_value.copyWith(config: value) as $Val);
    });
  }

  /// Create a copy of UserInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserServerEntityCopyWith<$Res>? get userServer {
    if (_value.userServer == null) {
      return null;
    }

    return $UserServerEntityCopyWith<$Res>(_value.userServer!, (value) {
      return _then(_value.copyWith(userServer: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserInfoEntityImplCopyWith<$Res>
    implements $UserInfoEntityCopyWith<$Res> {
  factory _$$UserInfoEntityImplCopyWith(
    _$UserInfoEntityImpl value,
    $Res Function(_$UserInfoEntityImpl) then,
  ) = __$$UserInfoEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
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
    UserServerEntity? userServer,
    bool? steamTokenUse,
    int? assetTotalNum,
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
    bool swindle,
    bool vip,
  });

  @override
  $UserShopEntityCopyWith<$Res>? get shop;
  @override
  $UserFundEntityCopyWith<$Res>? get fund;
  @override
  $UserSteamConfigEntityCopyWith<$Res>? get config;
  @override
  $UserServerEntityCopyWith<$Res>? get userServer;
}

/// @nodoc
class __$$UserInfoEntityImplCopyWithImpl<$Res>
    extends _$UserInfoEntityCopyWithImpl<$Res, _$UserInfoEntityImpl>
    implements _$$UserInfoEntityImplCopyWith<$Res> {
  __$$UserInfoEntityImplCopyWithImpl(
    _$UserInfoEntityImpl _value,
    $Res Function(_$UserInfoEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? uuid = freezed,
    Object? avatar = freezed,
    Object? appUse = freezed,
    Object? account = freezed,
    Object? nickname = freezed,
    Object? showEmail = freezed,
    Object? need2FA = freezed,
    Object? shop = freezed,
    Object? isBan = freezed,
    Object? isBlack = freezed,
    Object? fund = freezed,
    Object? config = freezed,
    Object? userServer = freezed,
    Object? steamTokenUse = freezed,
    Object? assetTotalNum = freezed,
    Object? autoManage = freezed,
    Object? autoReceive = freezed,
    Object? banReason = freezed,
    Object? code = freezed,
    Object? commissionFreeUser = freezed,
    Object? errorCount = freezed,
    Object? identityId = freezed,
    Object? isEnableCommission = freezed,
    Object? isManage = freezed,
    Object? lastIp = freezed,
    Object? lastLoginTime = freezed,
    Object? loggerShowName = freezed,
    Object? loginAddress = freezed,
    Object? loginMode = freezed,
    Object? memberLevel = freezed,
    Object? memberType = freezed,
    Object? mobile = freezed,
    Object? note = freezed,
    Object? realNickname = freezed,
    Object? registerTime = freezed,
    Object? safeTokenName = freezed,
    Object? safeTokenStatus = freezed,
    Object? selfOwned = freezed,
    Object? sendType = freezed,
    Object? flag = freezed,
    Object? swindle = null,
    Object? vip = null,
  }) {
    return _then(
      _$UserInfoEntityImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        uuid: freezed == uuid
            ? _value.uuid
            : uuid // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatar: freezed == avatar
            ? _value.avatar
            : avatar // ignore: cast_nullable_to_non_nullable
                  as String?,
        appUse: freezed == appUse
            ? _value.appUse
            : appUse // ignore: cast_nullable_to_non_nullable
                  as String?,
        account: freezed == account
            ? _value.account
            : account // ignore: cast_nullable_to_non_nullable
                  as String?,
        nickname: freezed == nickname
            ? _value.nickname
            : nickname // ignore: cast_nullable_to_non_nullable
                  as String?,
        showEmail: freezed == showEmail
            ? _value.showEmail
            : showEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        need2FA: freezed == need2FA
            ? _value.need2FA
            : need2FA // ignore: cast_nullable_to_non_nullable
                  as bool?,
        shop: freezed == shop
            ? _value.shop
            : shop // ignore: cast_nullable_to_non_nullable
                  as UserShopEntity?,
        isBan: freezed == isBan
            ? _value.isBan
            : isBan // ignore: cast_nullable_to_non_nullable
                  as bool?,
        isBlack: freezed == isBlack
            ? _value.isBlack
            : isBlack // ignore: cast_nullable_to_non_nullable
                  as bool?,
        fund: freezed == fund
            ? _value.fund
            : fund // ignore: cast_nullable_to_non_nullable
                  as UserFundEntity?,
        config: freezed == config
            ? _value.config
            : config // ignore: cast_nullable_to_non_nullable
                  as UserSteamConfigEntity?,
        userServer: freezed == userServer
            ? _value.userServer
            : userServer // ignore: cast_nullable_to_non_nullable
                  as UserServerEntity?,
        steamTokenUse: freezed == steamTokenUse
            ? _value.steamTokenUse
            : steamTokenUse // ignore: cast_nullable_to_non_nullable
                  as bool?,
        assetTotalNum: freezed == assetTotalNum
            ? _value.assetTotalNum
            : assetTotalNum // ignore: cast_nullable_to_non_nullable
                  as int?,
        autoManage: freezed == autoManage
            ? _value.autoManage
            : autoManage // ignore: cast_nullable_to_non_nullable
                  as bool?,
        autoReceive: freezed == autoReceive
            ? _value.autoReceive
            : autoReceive // ignore: cast_nullable_to_non_nullable
                  as bool?,
        banReason: freezed == banReason
            ? _value.banReason
            : banReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        code: freezed == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String?,
        commissionFreeUser: freezed == commissionFreeUser
            ? _value.commissionFreeUser
            : commissionFreeUser // ignore: cast_nullable_to_non_nullable
                  as bool?,
        errorCount: freezed == errorCount
            ? _value.errorCount
            : errorCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        identityId: freezed == identityId
            ? _value.identityId
            : identityId // ignore: cast_nullable_to_non_nullable
                  as String?,
        isEnableCommission: freezed == isEnableCommission
            ? _value.isEnableCommission
            : isEnableCommission // ignore: cast_nullable_to_non_nullable
                  as bool?,
        isManage: freezed == isManage
            ? _value.isManage
            : isManage // ignore: cast_nullable_to_non_nullable
                  as bool?,
        lastIp: freezed == lastIp
            ? _value.lastIp
            : lastIp // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastLoginTime: freezed == lastLoginTime
            ? _value.lastLoginTime
            : lastLoginTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        loggerShowName: freezed == loggerShowName
            ? _value.loggerShowName
            : loggerShowName // ignore: cast_nullable_to_non_nullable
                  as String?,
        loginAddress: freezed == loginAddress
            ? _value.loginAddress
            : loginAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        loginMode: freezed == loginMode
            ? _value.loginMode
            : loginMode // ignore: cast_nullable_to_non_nullable
                  as int?,
        memberLevel: freezed == memberLevel
            ? _value.memberLevel
            : memberLevel // ignore: cast_nullable_to_non_nullable
                  as int?,
        memberType: freezed == memberType
            ? _value.memberType
            : memberType // ignore: cast_nullable_to_non_nullable
                  as int?,
        mobile: freezed == mobile
            ? _value.mobile
            : mobile // ignore: cast_nullable_to_non_nullable
                  as String?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        realNickname: freezed == realNickname
            ? _value.realNickname
            : realNickname // ignore: cast_nullable_to_non_nullable
                  as String?,
        registerTime: freezed == registerTime
            ? _value.registerTime
            : registerTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        safeTokenName: freezed == safeTokenName
            ? _value.safeTokenName
            : safeTokenName // ignore: cast_nullable_to_non_nullable
                  as String?,
        safeTokenStatus: freezed == safeTokenStatus
            ? _value.safeTokenStatus
            : safeTokenStatus // ignore: cast_nullable_to_non_nullable
                  as bool?,
        selfOwned: freezed == selfOwned
            ? _value.selfOwned
            : selfOwned // ignore: cast_nullable_to_non_nullable
                  as bool?,
        sendType: freezed == sendType
            ? _value.sendType
            : sendType // ignore: cast_nullable_to_non_nullable
                  as int?,
        flag: freezed == flag
            ? _value.flag
            : flag // ignore: cast_nullable_to_non_nullable
                  as bool?,
        swindle: null == swindle
            ? _value.swindle
            : swindle // ignore: cast_nullable_to_non_nullable
                  as bool,
        vip: null == vip
            ? _value.vip
            : vip // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserInfoEntityImpl implements _UserInfoEntity {
  const _$UserInfoEntityImpl({
    this.id,
    this.uuid,
    this.avatar,
    this.appUse,
    this.account,
    this.nickname,
    this.showEmail,
    this.need2FA,
    this.shop,
    this.isBan,
    this.isBlack,
    this.fund,
    this.config,
    this.userServer,
    this.steamTokenUse,
    this.assetTotalNum,
    this.autoManage,
    this.autoReceive,
    this.banReason,
    this.code,
    this.commissionFreeUser,
    this.errorCount,
    this.identityId,
    this.isEnableCommission,
    this.isManage,
    this.lastIp,
    this.lastLoginTime,
    this.loggerShowName,
    this.loginAddress,
    this.loginMode,
    this.memberLevel,
    this.memberType,
    this.mobile,
    this.note,
    this.realNickname,
    this.registerTime,
    this.safeTokenName,
    this.safeTokenStatus,
    this.selfOwned,
    this.sendType,
    this.flag,
    this.swindle = false,
    this.vip = false,
  });

  factory _$UserInfoEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserInfoEntityImplFromJson(json);

  @override
  final String? id;
  @override
  final String? uuid;
  @override
  final String? avatar;
  @override
  final String? appUse;
  @override
  final String? account;
  @override
  final String? nickname;
  @override
  final String? showEmail;
  @override
  final bool? need2FA;
  @override
  final UserShopEntity? shop;
  @override
  final bool? isBan;
  @override
  final bool? isBlack;
  @override
  final UserFundEntity? fund;
  @override
  final UserSteamConfigEntity? config;
  @override
  final UserServerEntity? userServer;
  // 可为 null
  @override
  final bool? steamTokenUse;
  @override
  final int? assetTotalNum;
  // 你接口没返回，默认为0或加字段
  @override
  final bool? autoManage;
  @override
  final bool? autoReceive;
  @override
  final String? banReason;
  @override
  final String? code;
  @override
  final bool? commissionFreeUser;
  @override
  final int? errorCount;
  @override
  final String? identityId;
  @override
  final bool? isEnableCommission;
  @override
  final bool? isManage;
  @override
  final String? lastIp;
  @override
  final String? lastLoginTime;
  @override
  final String? loggerShowName;
  @override
  final String? loginAddress;
  @override
  final int? loginMode;
  @override
  final int? memberLevel;
  @override
  final int? memberType;
  @override
  final String? mobile;
  @override
  final String? note;
  @override
  final String? realNickname;
  @override
  final String? registerTime;
  @override
  final String? safeTokenName;
  @override
  final bool? safeTokenStatus;
  @override
  final bool? selfOwned;
  @override
  final int? sendType;
  @override
  final bool? flag;
  @override
  @JsonKey()
  final bool swindle;
  @override
  @JsonKey()
  final bool vip;

  @override
  String toString() {
    return 'UserInfoEntity(id: $id, uuid: $uuid, avatar: $avatar, appUse: $appUse, account: $account, nickname: $nickname, showEmail: $showEmail, need2FA: $need2FA, shop: $shop, isBan: $isBan, isBlack: $isBlack, fund: $fund, config: $config, userServer: $userServer, steamTokenUse: $steamTokenUse, assetTotalNum: $assetTotalNum, autoManage: $autoManage, autoReceive: $autoReceive, banReason: $banReason, code: $code, commissionFreeUser: $commissionFreeUser, errorCount: $errorCount, identityId: $identityId, isEnableCommission: $isEnableCommission, isManage: $isManage, lastIp: $lastIp, lastLoginTime: $lastLoginTime, loggerShowName: $loggerShowName, loginAddress: $loginAddress, loginMode: $loginMode, memberLevel: $memberLevel, memberType: $memberType, mobile: $mobile, note: $note, realNickname: $realNickname, registerTime: $registerTime, safeTokenName: $safeTokenName, safeTokenStatus: $safeTokenStatus, selfOwned: $selfOwned, sendType: $sendType, flag: $flag, swindle: $swindle, vip: $vip)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserInfoEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.appUse, appUse) || other.appUse == appUse) &&
            (identical(other.account, account) || other.account == account) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.showEmail, showEmail) ||
                other.showEmail == showEmail) &&
            (identical(other.need2FA, need2FA) || other.need2FA == need2FA) &&
            (identical(other.shop, shop) || other.shop == shop) &&
            (identical(other.isBan, isBan) || other.isBan == isBan) &&
            (identical(other.isBlack, isBlack) || other.isBlack == isBlack) &&
            (identical(other.fund, fund) || other.fund == fund) &&
            (identical(other.config, config) || other.config == config) &&
            (identical(other.userServer, userServer) ||
                other.userServer == userServer) &&
            (identical(other.steamTokenUse, steamTokenUse) ||
                other.steamTokenUse == steamTokenUse) &&
            (identical(other.assetTotalNum, assetTotalNum) ||
                other.assetTotalNum == assetTotalNum) &&
            (identical(other.autoManage, autoManage) ||
                other.autoManage == autoManage) &&
            (identical(other.autoReceive, autoReceive) ||
                other.autoReceive == autoReceive) &&
            (identical(other.banReason, banReason) ||
                other.banReason == banReason) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.commissionFreeUser, commissionFreeUser) ||
                other.commissionFreeUser == commissionFreeUser) &&
            (identical(other.errorCount, errorCount) ||
                other.errorCount == errorCount) &&
            (identical(other.identityId, identityId) ||
                other.identityId == identityId) &&
            (identical(other.isEnableCommission, isEnableCommission) ||
                other.isEnableCommission == isEnableCommission) &&
            (identical(other.isManage, isManage) ||
                other.isManage == isManage) &&
            (identical(other.lastIp, lastIp) || other.lastIp == lastIp) &&
            (identical(other.lastLoginTime, lastLoginTime) ||
                other.lastLoginTime == lastLoginTime) &&
            (identical(other.loggerShowName, loggerShowName) ||
                other.loggerShowName == loggerShowName) &&
            (identical(other.loginAddress, loginAddress) ||
                other.loginAddress == loginAddress) &&
            (identical(other.loginMode, loginMode) ||
                other.loginMode == loginMode) &&
            (identical(other.memberLevel, memberLevel) ||
                other.memberLevel == memberLevel) &&
            (identical(other.memberType, memberType) ||
                other.memberType == memberType) &&
            (identical(other.mobile, mobile) || other.mobile == mobile) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.realNickname, realNickname) ||
                other.realNickname == realNickname) &&
            (identical(other.registerTime, registerTime) ||
                other.registerTime == registerTime) &&
            (identical(other.safeTokenName, safeTokenName) ||
                other.safeTokenName == safeTokenName) &&
            (identical(other.safeTokenStatus, safeTokenStatus) ||
                other.safeTokenStatus == safeTokenStatus) &&
            (identical(other.selfOwned, selfOwned) ||
                other.selfOwned == selfOwned) &&
            (identical(other.sendType, sendType) ||
                other.sendType == sendType) &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.swindle, swindle) || other.swindle == swindle) &&
            (identical(other.vip, vip) || other.vip == vip));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    uuid,
    avatar,
    appUse,
    account,
    nickname,
    showEmail,
    need2FA,
    shop,
    isBan,
    isBlack,
    fund,
    config,
    userServer,
    steamTokenUse,
    assetTotalNum,
    autoManage,
    autoReceive,
    banReason,
    code,
    commissionFreeUser,
    errorCount,
    identityId,
    isEnableCommission,
    isManage,
    lastIp,
    lastLoginTime,
    loggerShowName,
    loginAddress,
    loginMode,
    memberLevel,
    memberType,
    mobile,
    note,
    realNickname,
    registerTime,
    safeTokenName,
    safeTokenStatus,
    selfOwned,
    sendType,
    flag,
    swindle,
    vip,
  ]);

  /// Create a copy of UserInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserInfoEntityImplCopyWith<_$UserInfoEntityImpl> get copyWith =>
      __$$UserInfoEntityImplCopyWithImpl<_$UserInfoEntityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserInfoEntityImplToJson(this);
  }
}

abstract class _UserInfoEntity implements UserInfoEntity {
  const factory _UserInfoEntity({
    final String? id,
    final String? uuid,
    final String? avatar,
    final String? appUse,
    final String? account,
    final String? nickname,
    final String? showEmail,
    final bool? need2FA,
    final UserShopEntity? shop,
    final bool? isBan,
    final bool? isBlack,
    final UserFundEntity? fund,
    final UserSteamConfigEntity? config,
    final UserServerEntity? userServer,
    final bool? steamTokenUse,
    final int? assetTotalNum,
    final bool? autoManage,
    final bool? autoReceive,
    final String? banReason,
    final String? code,
    final bool? commissionFreeUser,
    final int? errorCount,
    final String? identityId,
    final bool? isEnableCommission,
    final bool? isManage,
    final String? lastIp,
    final String? lastLoginTime,
    final String? loggerShowName,
    final String? loginAddress,
    final int? loginMode,
    final int? memberLevel,
    final int? memberType,
    final String? mobile,
    final String? note,
    final String? realNickname,
    final String? registerTime,
    final String? safeTokenName,
    final bool? safeTokenStatus,
    final bool? selfOwned,
    final int? sendType,
    final bool? flag,
    final bool swindle,
    final bool vip,
  }) = _$UserInfoEntityImpl;

  factory _UserInfoEntity.fromJson(Map<String, dynamic> json) =
      _$UserInfoEntityImpl.fromJson;

  @override
  String? get id;
  @override
  String? get uuid;
  @override
  String? get avatar;
  @override
  String? get appUse;
  @override
  String? get account;
  @override
  String? get nickname;
  @override
  String? get showEmail;
  @override
  bool? get need2FA;
  @override
  UserShopEntity? get shop;
  @override
  bool? get isBan;
  @override
  bool? get isBlack;
  @override
  UserFundEntity? get fund;
  @override
  UserSteamConfigEntity? get config;
  @override
  UserServerEntity? get userServer; // 可为 null
  @override
  bool? get steamTokenUse;
  @override
  int? get assetTotalNum; // 你接口没返回，默认为0或加字段
  @override
  bool? get autoManage;
  @override
  bool? get autoReceive;
  @override
  String? get banReason;
  @override
  String? get code;
  @override
  bool? get commissionFreeUser;
  @override
  int? get errorCount;
  @override
  String? get identityId;
  @override
  bool? get isEnableCommission;
  @override
  bool? get isManage;
  @override
  String? get lastIp;
  @override
  String? get lastLoginTime;
  @override
  String? get loggerShowName;
  @override
  String? get loginAddress;
  @override
  int? get loginMode;
  @override
  int? get memberLevel;
  @override
  int? get memberType;
  @override
  String? get mobile;
  @override
  String? get note;
  @override
  String? get realNickname;
  @override
  String? get registerTime;
  @override
  String? get safeTokenName;
  @override
  bool? get safeTokenStatus;
  @override
  bool? get selfOwned;
  @override
  int? get sendType;
  @override
  bool? get flag;
  @override
  bool get swindle;
  @override
  bool get vip;

  /// Create a copy of UserInfoEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserInfoEntityImplCopyWith<_$UserInfoEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
