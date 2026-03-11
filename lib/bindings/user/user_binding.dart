import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';

class UserBinding extends Bindings {
  final logger = Logger();

  @override
  void dependencies() {
    logger.d("UserBinding dependencies() 执行了！");
    Get.lazyPut<UserController>(() => UserController()); // 推荐 lazyPut
  }
}
