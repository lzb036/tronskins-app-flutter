import 'package:get_storage/get_storage.dart';
import 'package:tronskins_app/api/model/entity/user/user_info_entity.dart';

class UserStorage {
  UserStorage._();

  static final GetStorage _box = GetStorage();
  static const String _userInfoKey = 'es_user_info';

  static UserInfoEntity? getUserInfo() {
    final raw = _box.read(_userInfoKey);
    if (raw is Map<String, dynamic>) {
      return UserInfoEntity.fromJson(
        _normalizeUserInfoMap(Map<String, dynamic>.from(raw)),
      );
    }
    if (raw is Map) {
      return UserInfoEntity.fromJson(
        _normalizeUserInfoMap(Map<String, dynamic>.from(raw)),
      );
    }
    return null;
  }

  static UserInfoEntity mergeUserInfo(
    UserInfoEntity userInfo, {
    UserInfoEntity? fallbackUserInfo,
  }) {
    final previousUserInfo = fallbackUserInfo ?? getUserInfo();
    final mergedAppUse = _firstNonEmptyString(
      userInfo.appUse,
      previousUserInfo?.appUse,
    );
    return userInfo.copyWith(appUse: mergedAppUse);
  }

  static void setUserInfo(UserInfoEntity? userInfo) {
    if (userInfo == null) {
      _box.remove(_userInfoKey);
      return;
    }
    final mergedUserInfo = mergeUserInfo(userInfo);
    final data = Map<String, dynamic>.from(mergedUserInfo.toJson());
    data['shop'] = mergedUserInfo.shop?.toJson();
    data['fund'] = mergedUserInfo.fund?.toJson();
    data['config'] = mergedUserInfo.config?.toJson();
    data['userServer'] = mergedUserInfo.userServer?.toJson();
    _box.write(_userInfoKey, data);
  }

  static Map<String, dynamic> _normalizeUserInfoMap(Map<String, dynamic> data) {
    data['shop'] = _coerceMap(data['shop']);
    data['fund'] = _coerceMap(data['fund']);
    data['config'] = _coerceMap(data['config']);
    data['userServer'] = _coerceMap(data['userServer']);
    return data;
  }

  static Map<String, dynamic>? _coerceMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    try {
      final json = (value as dynamic).toJson();
      if (json is Map) {
        return Map<String, dynamic>.from(json);
      }
    } catch (_) {}
    return null;
  }

  static String? _firstNonEmptyString(String? primary, String? fallback) {
    if (primary != null && primary.trim().isNotEmpty) {
      return primary;
    }
    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback;
    }
    return primary ?? fallback;
  }
}
