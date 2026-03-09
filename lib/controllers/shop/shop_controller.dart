import 'package:get/get.dart';
import 'package:tronskins_app/api/shop.dart';
import 'package:tronskins_app/api/model/entity/user/user_shop_entity.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/common/events/app_events.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';

class ShopController extends GetxController {
  final ApiShopServer _api = ApiShopServer();
  final UserController _userController = Get.find<UserController>();

  final Rx<UserShopEntity?> shop = Rx<UserShopEntity?>(null);
  final RxBool isLoading = false.obs;
  Worker? _loginWorker;
  Worker? _logoutWorker;

  @override
  void onInit() {
    super.onInit();
    if (_userController.isLoggedIn.value) {
      loadShop();
    }
    _loginWorker = ever<bool>(_userController.isLoggedIn, (loggedIn) {
      if (loggedIn) {
        loadShop();
      } else {
        shop.value = null;
      }
    });
    // 监听退出登录事件
    _logoutWorker = ever(AppEvents.userLogoutEvent, (_) {
      shop.value = null;
    });
  }

  @override
  void onClose() {
    _loginWorker?.dispose();
    _logoutWorker?.dispose();
    super.onClose();
  }

  Future<void> loadShop() async {
    if (isLoading.value) {
      return;
    }
    isLoading.value = true;
    try {
      await _userController.fetchUserData(showLoading: false);
      shop.value = _userController.user.value?.shop;
    } finally {
      isLoading.value = false;
    }
  }

  Future<BaseHttpResponse<dynamic>> toggleShopStatus() async {
    final res = await _api.changeShopStatus();
    if (res.success) {
      await loadShop();
    }
    return res;
  }

  Future<BaseHttpResponse<dynamic>> toggleAutoOffline(bool enabled) async {
    final res = await _api.changeAutoOffline(openAutoClose: enabled);
    if (res.success) {
      await loadShop();
    }
    return res;
  }

  Future<void> changeShopName(String name) async {
    await _api.changeShopName(shopName: name);
    await loadShop();
  }

  Future<void> setAutoCloseTime(int hour, int minute) async {
    await _api.setAutoCloseTime(hour: hour, minute: minute);
    await loadShop();
  }
}
