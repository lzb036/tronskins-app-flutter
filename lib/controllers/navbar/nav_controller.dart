import 'package:get/get.dart';

class NavController extends GetxController {
  static const int tabHome = 0;
  static const int tabMarket = 1;
  static const int tabInventory = 2;
  static const int tabSell = 3;
  static const int tabMine = 4;

  static const int shopTabOnSale = 0;
  static const int shopTabPending = 1;
  static const int shopTabSaleRecord = 2;

  final RxInt currentIndex = 0.obs;
  final RxnInt pendingShopTabIndex = RxnInt();

  void switchTo(int index) {
    if (currentIndex.value == index) {
      return;
    }
    currentIndex.value = index;
  }

  void switchToShopTab(int tabIndex) {
    pendingShopTabIndex.value = tabIndex;
    switchTo(tabSell);
  }

  void clearPendingShopTab() {
    pendingShopTabIndex.value = null;
  }
}
