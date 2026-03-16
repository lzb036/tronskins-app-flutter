import 'package:get/get.dart';
import 'package:tronskins_app/api/loginServer.dart';
import 'package:tronskins_app/api/wallet.dart';
import 'package:tronskins_app/api/model/entity/user/user_info_entity.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';

class IntegralController extends GetxController {
  IntegralController({ApiWalletServer? api, ApiLoginServer? userApi})
    : _api = api ?? ApiWalletServer(),
      _userApi = userApi ?? ApiLoginServer();

  final ApiWalletServer _api;
  final ApiLoginServer _userApi;

  final Rx<UserInfoEntity?> userInfo = Rx<UserInfoEntity?>(null);
  final RxBool isLoadingUser = false.obs;

  final RxList<WalletCouponItem> couponItems = <WalletCouponItem>[].obs;
  final RxBool isLoadingCoupons = false.obs;

  final RxList<WalletLotteryPrize> lotteryPrizes = <WalletLotteryPrize>[].obs;
  final RxBool isLoadingLottery = false.obs;

  @override
  void onInit() {
    super.onInit();
    userInfo.value = UserStorage.getUserInfo();
  }

  int get integralValue {
    final raw = userInfo.value?.fund?.integral;
    if (raw == null) {
      return 0;
    }
    final parsed = int.tryParse(raw.toString());
    return parsed ?? 0;
  }

  Future<void> refreshUser({bool showLoading = false}) async {
    if (isLoadingUser.value && showLoading) {
      return;
    }
    if (showLoading) {
      isLoadingUser.value = true;
    }
    try {
      final res = await _userApi.getUserApi();
      if (res.success && res.datas != null) {
        final mergedUserInfo = UserStorage.mergeUserInfo(
          res.datas!,
          fallbackUserInfo: userInfo.value,
        );
        userInfo.value = mergedUserInfo;
        UserStorage.setUserInfo(mergedUserInfo);
        if (Get.isRegistered<UserController>()) {
          await Get.find<UserController>().fetchUserData(showLoading: false);
        }
      }
    } finally {
      isLoadingUser.value = false;
    }
  }

  Future<void> loadCouponsList() async {
    if (isLoadingCoupons.value) {
      return;
    }
    isLoadingCoupons.value = true;
    try {
      final res = await _api.couponsList();
      if (res.success) {
        couponItems.assignAll(res.datas ?? <WalletCouponItem>[]);
      }
    } finally {
      isLoadingCoupons.value = false;
    }
  }

  Future<bool> exchangeCoupon(int type) async {
    final res = await _api.couponsExchange(type: type);
    if (res.success) {
      await refreshUser();
      return true;
    }
    return false;
  }

  Future<void> loadLotteryPrizes() async {
    if (isLoadingLottery.value) {
      return;
    }
    isLoadingLottery.value = true;
    try {
      final res = await _api.lotteryPrizeList();
      if (res.success) {
        lotteryPrizes.assignAll(res.datas ?? <WalletLotteryPrize>[]);
      }
    } finally {
      isLoadingLottery.value = false;
    }
  }

  Future<WalletLotteryResult?> drawLottery() async {
    final res = await _api.integralLottery();
    if (res.success) {
      await refreshUser();
      return res.datas;
    }
    return null;
  }
}
