import 'package:get/get.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';

/// 全局游戏上下文：
/// 任意页面切换游戏后，通过该控制器广播给全应用。
class GlobalGameController extends GetxService {
  final RxInt currentAppId = 730.obs;

  int get appId => currentAppId.value;

  static GlobalGameController ensureInstance() {
    if (Get.isRegistered<GlobalGameController>()) {
      return Get.find<GlobalGameController>();
    }
    return Get.put(GlobalGameController(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    currentAppId.value = GameStorage.getGameType();
  }

  Future<void> switchGame(int nextAppId) async {
    if (nextAppId == currentAppId.value) {
      return;
    }
    // 先更新内存态，确保界面能即时响应；再异步持久化。
    currentAppId.value = nextAppId;
    await GameStorage.setGameType(nextAppId);
  }

  void syncFromStorage() {
    final stored = GameStorage.getGameType();
    if (stored != currentAppId.value) {
      currentAppId.value = stored;
    }
  }
}
