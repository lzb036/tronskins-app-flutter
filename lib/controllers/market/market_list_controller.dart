import 'dart:async';

import 'package:get/get.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/common/hooks/game/global_game_controller.dart';

class MarketListController extends GetxController {
  final ApiMarketServer _api = ApiMarketServer();
  final GlobalGameController _globalGameController =
      GlobalGameController.ensureInstance();
  static const int _pageSize = 20;

  final RxInt appId = 730.obs;
  final RxList<MarketItemEntity> items = <MarketItemEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt total = 0.obs;

  final RxString keywords = ''.obs;
  final RxString sortField = 'price'.obs;
  final RxBool sortAsc = false.obs;
  final RxnDouble priceMin = RxnDouble();
  final RxnDouble priceMax = RxnDouble();
  final RxnString itemName = RxnString();
  final RxMap<String, dynamic> tags = <String, dynamic>{}.obs;

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  Worker? _gameWorker;

  @override
  void onInit() {
    super.onInit();
    appId.value = _globalGameController.currentAppId.value;
    _gameWorker = ever<int>(_globalGameController.currentAppId, (nextAppId) {
      if (nextAppId == appId.value) {
        return;
      }
      appId.value = nextAppId;
      tags.clear();
      itemName.value = null;
      refresh();
    });
  }

  @override
  void onClose() {
    _gameWorker?.dispose();
    super.onClose();
  }

  @override
  Future<void> refresh({bool reset = true}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      items.clear();
    }
    await loadMore();
  }

  Future<void> loadMore() async {
    if (isLoading.value || !_hasMore) {
      return;
    }
    isLoading.value = true;
    try {
      final tagPayload = Map<String, dynamic>.from(tags)
        ..removeWhere((key, value) => value == null || value == '');
      final res = await _api.marketGameList(
        appId: appId.value,
        page: _page,
        pageSize: _pageSize,
        field: sortField.value,
        asc: sortAsc.value,
        keywords: keywords.value.isEmpty ? null : keywords.value,
        itemName: itemName.value,
        tags: tagPayload.isEmpty ? null : tagPayload,
        minPrice: priceMin.value,
        maxPrice: priceMax.value,
      );
      final data = res.datas;
      final list = data?.items ?? <MarketItemEntity>[];
      if (list.isEmpty) {
        _hasMore = false;
      } else {
        final fetchedCount = list.length;
        items.addAll(list);
        final totalCount = data?.pager?.total;
        if (totalCount != null && totalCount > 0) {
          _hasMore = items.length < totalCount;
        } else {
          _hasMore = fetchedCount >= _pageSize;
        }
        if (_hasMore) {
          _page += 1;
        }
      }
      total.value = data?.pager?.total ?? total.value;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> search(String value) async {
    keywords.value = value.trim();
    itemName.value = null;
    await refresh();
  }

  Future<void> applyFilter({
    String? field,
    bool? asc,
    double? minPrice,
    double? maxPrice,
    Map<String, dynamic>? tags,
    String? itemName,
    String? keyword,
  }) async {
    if (field != null) {
      sortField.value = field;
    }
    if (asc != null) {
      sortAsc.value = asc;
    }
    if (keyword != null) {
      keywords.value = keyword.trim();
    }
    priceMin.value = minPrice;
    priceMax.value = maxPrice;
    if (tags != null) {
      this.tags.value = Map<String, dynamic>.from(tags);
    }
    if (itemName != null) {
      this.itemName.value = itemName.isEmpty ? null : itemName;
    }
    await refresh();
  }

  Future<void> changeGame(int newAppId) async {
    await _globalGameController.switchGame(newAppId);
  }

  void applyInitialArgs(Map<String, dynamic>? args) {
    if (args == null) {
      return;
    }
    if (args.containsKey('appId')) {
      final rawAppId = args['appId'];
      final parsed = rawAppId is int
          ? rawAppId
          : int.tryParse(rawAppId?.toString() ?? '');
      if (parsed != null && parsed != appId.value) {
        appId.value = parsed;
        unawaited(_globalGameController.switchGame(parsed));
      }
    }
    if (args.containsKey('keyword')) {
      final keyword = args['keyword']?.toString() ?? '';
      keywords.value = keyword;
    }
    if (args.containsKey('sortField')) {
      final field = args['sortField']?.toString();
      if (field != null) {
        sortField.value = field;
      }
    }
    if (args.containsKey('sortAsc')) {
      final asc = args['sortAsc'];
      if (asc is bool) {
        sortAsc.value = asc;
      }
    }
    if (args.containsKey('minPrice')) {
      final min = args['minPrice'];
      if (min is num) {
        priceMin.value = min.toDouble();
      } else {
        priceMin.value = min != null ? double.tryParse(min.toString()) : null;
      }
    }
    if (args.containsKey('maxPrice')) {
      final max = args['maxPrice'];
      if (max is num) {
        priceMax.value = max.toDouble();
      } else {
        priceMax.value = max != null ? double.tryParse(max.toString()) : null;
      }
    }
    if (args.containsKey('itemName')) {
      final rawItemName = args['itemName']?.toString() ?? '';
      itemName.value = rawItemName.isEmpty ? null : rawItemName;
    }
    if (args.containsKey('tags')) {
      final rawTags = args['tags'];
      if (rawTags is Map) {
        final map = <String, dynamic>{};
        rawTags.forEach((key, value) {
          map[key.toString()] = value;
        });
        tags.value = map;
      } else {
        tags.clear();
      }
    }
  }
}
