import 'package:get/get.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';

class MarketListController extends GetxController {
  final ApiMarketServer _api = ApiMarketServer();

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

  @override
  void onInit() {
    super.onInit();
    appId.value = GameStorage.getGameType();
  }

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
        pageSize: 20,
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
        items.addAll(list);
        _page += 1;
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
    if (newAppId == appId.value) {
      return;
    }
    appId.value = newAppId;
    await GameStorage.setGameType(newAppId);
    tags.clear();
    itemName.value = null;
    await refresh();
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
        GameStorage.setGameType(parsed);
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
