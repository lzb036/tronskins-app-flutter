import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';

class CurrencyBinding extends Bindings {
  final logger = Logger();

  @override
  void dependencies() {
    logger.d("CurrencyBinding dependencies() 执行了！");
    Get.lazyPut<CurrencyController>(() => CurrencyController()); // 推荐 lazyPut
  }
}
