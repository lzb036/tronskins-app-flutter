import 'package:get/get.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';

class HomeController extends GetxController {
  final ApiMarketServer _api = ApiMarketServer();

  final RxInt appId = 730.obs;
  final RxList<MarketItemEntity> latestItems = <MarketItemEntity>[].obs;
  final RxList<MarketItemEntity> hotItems = <MarketItemEntity>[].obs;
  final RxBool isLoadingLatest = false.obs;
  final RxBool isLoadingHot = false.obs;

  int _latestPage = 1;
  int _hotPage = 1;
  bool _latestHasMore = true;
  bool _hotHasMore = true;

  bool get latestHasMore => _latestHasMore;
  bool get hotHasMore => _hotHasMore;

  @override
  void onInit() {
    super.onInit();
    appId.value = GameStorage.getGameType();
    refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchLatest(reset: true),
      fetchHot(reset: true),
    ]);
  }

  Future<void> changeGame(int newAppId) async {
    if (newAppId == appId.value) {
      return;
    }
    appId.value = newAppId;
    await GameStorage.setGameType(newAppId);
    await refreshAll();
  }

  Future<void> fetchLatest({bool reset = false}) async {
    if (isLoadingLatest.value || (!_latestHasMore && !reset)) {
      return;
    }
    isLoadingLatest.value = true;
    try {
      if (reset) {
        _latestPage = 1;
        _latestHasMore = true;
        latestItems.clear();
      }
      final res = await _api.marketNews(
        appId: appId.value,
        page: _latestPage,
        pageSize: 10,
      );
      final items = res.datas ?? <MarketItemEntity>[];
      if (items.isEmpty) {
        _latestHasMore = false;
      } else {
        latestItems.addAll(items);
        _latestPage += 1;
      }
    } finally {
      isLoadingLatest.value = false;
    }
  }

  Future<void> fetchHot({bool reset = false}) async {
    if (isLoadingHot.value || (!_hotHasMore && !reset)) {
      return;
    }
    isLoadingHot.value = true;
    try {
      if (reset) {
        _hotPage = 1;
        _hotHasMore = true;
        hotItems.clear();
      }
      final res = await _api.marketHotItems(
        appId: appId.value,
        page: _hotPage,
        pageSize: 20,
      );
      final items = res.datas ?? <MarketItemEntity>[];
      if (items.isEmpty) {
        _hotHasMore = false;
      } else {
        hotItems.addAll(items);
        _hotPage += 1;
      }
    } finally {
      isLoadingHot.value = false;
    }
  }
}
