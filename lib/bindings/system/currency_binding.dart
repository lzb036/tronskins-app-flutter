import 'package:get/get.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';

class CurrencyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CurrencyController>(() => CurrencyController()); // 推荐 lazyPut
  }
}
