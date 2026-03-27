// lib/controllers/user_controller.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tronskins_app/api/loginServer.dart';
import 'package:tronskins_app/api/model/entity/user/user_info_entity.dart';
import 'package:tronskins_app/common/events/app_events.dart';
import 'package:tronskins_app/common/http/interceptors/auth_interceptor.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/storage/app_cache.dart';
import 'package:tronskins_app/common/storage/server_storage.dart';
import 'package:tronskins_app/common/storage/twofa_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class UserController extends GetxController {
  static const String _imageBaseUrl = 'https://www.tronskins.com/fms/image';
  // ==================== 鍝嶅簲寮忕姸鎬?====================
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;

  // 鍏抽敭锛氱敤 late + Rx锛岄伩鍏?null 瀹夊叏璀﹀憡
  final Rx<UserInfoEntity?> user = Rx<UserInfoEntity?>(null);

  // ==================== 璁＄畻灞炴€э紙瓒呭畨鍏ㄥ啓娉曪級================
  ImageProvider get avatarProvider {
    final avatar = user.value?.avatar;
    final resolved = _resolveAvatarUrl(avatar);
    if (isLoggedIn.value && resolved.isNotEmpty) {
      return CachedNetworkImageProvider(resolved);
    }
    return const AssetImage('assets/images/user/none.png');
  }

  String get nickname {
    if (!isLoggedIn.value) return '';
    final name = user.value?.nickname;
    if (name != null && name.isNotEmpty) return name;
    return '';
  }

  String get email {
    if (!isLoggedIn.value) return '';
    final safeEmail = user.value?.safeTokenName;
    if (safeEmail != null && safeEmail.isNotEmpty) return safeEmail;
    final name = user.value?.showEmail;
    if (name != null && name.isNotEmpty) return name;
    return '';
  }

  String get balance {
    final b = user.value?.fund?.balance;
    return b != null ? b.toStringAsFixed(2) : '0.00';
  }

  String get gift {
    final g = user.value?.fund?.gift;
    return g != null ? g.toStringAsFixed(0) : '0';
  }

  double get balanceValue => user.value?.fund?.balance ?? 0;

  double get giftValue => user.value?.fund?.gift ?? 0;

  double get lockedValue => user.value?.fund?.locked ?? 0;

  double get settlementValue => user.value?.fund?.settlement ?? 0;

  String get integral {
    return user.value?.fund?.integral ?? '0';
  }

  // ==================== 鍒濆鍖?====================
  @override
  void onInit() {
    super.onInit();
    final cachedUser = UserStorage.getUserInfo();
    final hasToken = AuthInterceptor.hasToken;
    if (cachedUser != null && hasToken) {
      user.value = cachedUser;
      isLoggedIn.value = true;
    } else if (!hasToken) {
      clearSession();
    }
    // 寤惰繜涓€鐐圭偣鎵ц锛岄伩鍏嶅喎鍚姩鍗￠】锛堝彲閫変紭鍖栵級
    ever(isLoggedIn, (_) => update()); // 鐧诲綍鐘舵€佸彉浜嗗氨鍒锋柊椤甸潰
    if (AuthInterceptor.hasToken) {
      fetchUserData();
    }
  }

  // ==================== 鑾峰彇鐢ㄦ埛淇℃伅 ====================
  Future<void> fetchUserData({bool showLoading = true}) async {
    if (isLoading.value) return;

    if (showLoading) isLoading.value = true;

    try {
      final result = await ApiLoginServer().getUserApi();
      if (result.success && result.datas != null) {
        final mergedUserInfo = UserStorage.mergeUserInfo(
          result.datas!,
          fallbackUserInfo: user.value,
        );
        user.value = mergedUserInfo;
        isLoggedIn.value = true;
        UserStorage.setUserInfo(mergedUserInfo);
      } else if (result.code == 401) {
        clearSession();
      }
    } on HttpException catch (error) {
      if (error.dioError?.response?.statusCode == 401) {
        clearSession();
      }
    } catch (e, stackTrace) {
      debugPrint('UserController.fetchUserData failed: $e');
      debugPrintStack(
        label: 'UserController.fetchUserData stackTrace',
        stackTrace: stackTrace,
      );
      // 网络异常或数据解析异常时，保留本地用户信息
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== 閫€鍑虹櫥褰?====================
  Future<void> logout() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('app.system.tips.title'.tr),
        content: Text('app.user.login.logout_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('app.common.cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('app.common.confirm'.tr),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _doLogout();
    }
  }

  /// 瀹為檯鎵ц閫€鍑虹櫥褰曠殑鏂规硶
  Future<void> _doLogout() async {
    final currentUser = user.value ?? UserStorage.getUserInfo();
    try {
      // 1. 璋冪敤閫€鍑虹櫥褰?API
      await ApiLoginServer().logoutApi();

      // 2. 鍙戦€佸叏灞€閫€鍑轰簨浠讹紝閫氱煡鍏朵粬椤甸潰
      AppEvents.triggerUserLogout();
    } catch (_) {}

    // 3. 娓呴櫎缂撳瓨鍜屼會璇?
    final currentUserId = currentUser?.id ?? '';
    final currentAppUse = currentUser?.appUse ?? '';
    if (currentUserId.isNotEmpty && currentAppUse.isNotEmpty) {
      await TwoFactorStorage.removePendingTokenEntry(
        server: ServerStorage.getServer(),
        appUse: currentAppUse,
        userId: currentUserId,
      );
    }
    await AppCache.clearOnLogout();
    clearSession();

    // 4. 寤惰繜璺宠浆鍒扮敤鎴蜂腑蹇冮〉闈紙涓?tronskins-app 淇濇寔涓€鑷达級
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(Routers.USER);
  }

  // ==================== 绉佹湁鏂规硶 ====================
  void clearSession() {
    user.value = null;
    isLoggedIn.value = false;
    UserStorage.setUserInfo(null);
  }

  // ==================== 涓嬫媺鍒锋柊 ====================
  Future<void> onRefresh() => fetchUserData(showLoading: false);

  String _resolveAvatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return '';
    }
    if (avatar.startsWith('http')) {
      return avatar;
    }
    return '$_imageBaseUrl$avatar';
  }
}
