import 'package:get/get.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/common/hooks/game/global_game_controller.dart';

class HomeController extends GetxController {
  final ApiMarketServer _api = ApiMarketServer();
  final GlobalGameController _globalGameController =
      GlobalGameController.ensureInstance();
  static const int _latestPageSize = 10;
  static const int _hotPageSize = 20;

  final RxInt appId = 730.obs;
  final RxList<MarketItemEntity> latestItems = <MarketItemEntity>[].obs;
  final RxList<MarketItemEntity> hotItems = <MarketItemEntity>[].obs;
  final RxBool isLoadingLatest = false.obs;
  final RxBool isLoadingHot = false.obs;
  Worker? _gameWorker;

  int _latestPage = 1;
  int _hotPage = 1;
  bool _latestHasMore = true;
  bool _hotHasMore = true;

  bool get latestHasMore => _latestHasMore;
  bool get hotHasMore => _hotHasMore;

  @override
  void onInit() {
    super.onInit();
    appId.value = _globalGameController.currentAppId.value;
    _gameWorker = ever<int>(_globalGameController.currentAppId, (nextAppId) {
      if (nextAppId == appId.value) {
        return;
      }
      appId.value = nextAppId;
      refreshAll();
    });
    refreshAll();
  }

  @override
  void onClose() {
    _gameWorker?.dispose();
    super.onClose();
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchLatest(reset: true), fetchHot(reset: true)]);
  }

  Future<void> changeGame(int newAppId) async {
    await _globalGameController.switchGame(newAppId);
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
        pageSize: _latestPageSize,
      );
      final items = res.datas ?? <MarketItemEntity>[];
      final fetchedCount = items.length;
      if (fetchedCount == 0) {
        _latestHasMore = false;
      } else {
        latestItems.addAll(items);
        _latestHasMore = fetchedCount >= _latestPageSize;
        if (_latestHasMore) {
          _latestPage += 1;
        }
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
        pageSize: _hotPageSize,
      );
      final items = res.datas ?? <MarketItemEntity>[];
      final fetchedCount = items.length;
      if (fetchedCount == 0) {
        _hotHasMore = false;
      } else {
        hotItems.addAll(items);
        _hotHasMore = fetchedCount >= _hotPageSize;
        if (_hotHasMore) {
          _hotPage += 1;
        }
      }
    } finally {
      isLoadingHot.value = false;
    }
  }
}
