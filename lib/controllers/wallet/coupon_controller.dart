import 'package:get/get.dart';
import 'package:tronskins_app/api/wallet.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';

class CouponController extends GetxController {
  CouponController({ApiWalletServer? api}) : _api = api ?? ApiWalletServer();

  final ApiWalletServer _api;

  final RxList<WalletCouponRecord> coupons = <WalletCouponRecord>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> loadCoupons() async {
    if (isLoading.value) {
      return;
    }
    isLoading.value = true;
    try {
      final res = await _api.couponsRecords();
      if (res.success) {
        coupons.assignAll(res.datas ?? <WalletCouponRecord>[]);
      }
    } finally {
      isLoading.value = false;
    }
  }
}
