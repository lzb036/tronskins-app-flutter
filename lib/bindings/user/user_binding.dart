import 'package:get/get.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserController>(() => UserController()); // 推荐 lazyPut
  }
}
