import 'package:get/get.dart';
import 'package:tronskins_app/api/inventory.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/events/app_events.dart';
import 'package:tronskins_app/common/hooks/game/global_game_controller.dart';
import 'package:tronskins_app/common/http/interceptors/auth_interceptor.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class _InventoryStateSnapshot {
  const _InventoryStateSnapshot({
    required this.items,
    required this.schemas,
    required this.stickers,
    required this.total,
    required this.totalPrice,
    required this.page,
    required this.hasMore,
    required this.lastFetchedAt,
    required this.triedRemoteFreshForCurrentRefresh,
  });

  final List<InventoryItem> items;
  final Map<String, ShopSchemaInfo> schemas;
  final Map<String, dynamic> stickers;
  final int total;
  final double totalPrice;
  final int page;
  final bool hasMore;
  final DateTime? lastFetchedAt;
  final bool triedRemoteFreshForCurrentRefresh;
}

class InventoryController extends GetxController {
  final ApiInventoryServer _inventoryApi = ApiInventoryServer();
  final ApiShopProductServer _shopApi = ApiShopProductServer();
  final GlobalGameController _globalGameController =
      GlobalGameController.ensureInstance();
  static const int _inventoryPageSize = 20;

  final RxList<InventoryItem> items = <InventoryItem>[].obs;
  final RxMap<String, ShopSchemaInfo> schemas = <String, ShopSchemaInfo>{}.obs;
  final RxMap<String, dynamic> stickers = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxInt total = 0.obs;
  final RxDouble totalPrice = 0.0.obs;
  final RxSet<int> selectedIds = <int>{}.obs;
  final RxString keywords = ''.obs;
  final RxString sortField = 'price'.obs;
  final RxBool sortAsc = false.obs;
  final RxnDouble priceMin = RxnDouble();
  final RxnDouble priceMax = RxnDouble();
  final RxnString itemName = RxnString();
  final RxMap<String, dynamic> tags = <String, dynamic>{}.obs;
  final RxBool sellableOnly = false.obs;
  final RxBool coolingOnly = false.obs;

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  final Map<String, _InventoryStateSnapshot> _stateCache =
      <String, _InventoryStateSnapshot>{};
  final Set<String> _loadedStateKeys = <String>{};
  bool _isPreloadingStateBuckets = false;
  Worker? _logoutWorker;
  DateTime? _lastFetchedAt;
  bool _triedRemoteFreshForCurrentRefresh = false;

  static const Duration _refreshThreshold = Duration(minutes: 5);

  final RxInt currentAppId = 730.obs;
  int get appId => currentAppId.value;
  bool get _hasToken => AuthInterceptor.hasToken;
  Worker? _gameWorker;

  @override
  void onInit() {
    super.onInit();
    currentAppId.value = _globalGameController.currentAppId.value;
    _gameWorker = ever<int>(
      _globalGameController.currentAppId,
      _handleGlobalGameChanged,
    );
    _logoutWorker = ever(AppEvents.userLogoutEvent, (_) {
      items.clear();
      schemas.clear();
      stickers.clear();
      total.value = 0;
      totalPrice.value = 0;
      selectedIds.clear();
      itemName.value = null;
      tags.clear();
      sellableOnly.value = false;
      coolingOnly.value = false;
      _page = 1;
      _hasMore = true;
      _stateCache.clear();
      _loadedStateKeys.clear();
      _isPreloadingStateBuckets = false;
      _lastFetchedAt = null;
      _triedRemoteFreshForCurrentRefresh = false;
    });
  }

  bool get isStale {
    if (_lastFetchedAt == null) {
      return true;
    }
    return DateTime.now().difference(_lastFetchedAt!) >= _refreshThreshold;
  }

  Future<void> refreshIfStale() async {
    if (isStale) {
      await refreshList();
    }
  }

  @override
  void onClose() {
    _logoutWorker?.dispose();
    _gameWorker?.dispose();
    super.onClose();
  }

  void _handleGlobalGameChanged(int nextAppId) {
    if (nextAppId == currentAppId.value) {
      return;
    }
    currentAppId.value = nextAppId;
    tags.clear();
    itemName.value = null;
    _invalidateStateCache();
    clearSelection();

    if (!_hasToken) {
      items.clear();
      schemas.clear();
      stickers.clear();
      total.value = 0;
      totalPrice.value = 0;
      _page = 1;
      _hasMore = true;
      _lastFetchedAt = null;
      _triedRemoteFreshForCurrentRefresh = false;
      return;
    }

    Future.microtask(() async {
      if (isClosed) {
        return;
      }
      await refreshList();
      if (isClosed) {
        return;
      }
      await preloadStateBucketsIfNeeded(force: true);
    });
  }

  Future<void> refreshList() async {
    if (!_hasToken) {
      items.clear();
      schemas.clear();
      stickers.clear();
      total.value = 0;
      totalPrice.value = 0;
      _stateCache.clear();
      _loadedStateKeys.clear();
      _lastFetchedAt = null;
      return;
    }
    final key = _activeStateKey();
    _stateCache.remove(key);
    _loadedStateKeys.remove(key);
    _page = 1;
    _hasMore = true;
    _triedRemoteFreshForCurrentRefresh = false;
    items.clear();
    await loadMore();
  }

  Future<void> refreshByPullDown() async {
    clearSelection();
    await refreshList();
  }

  Future<void> loadMore() async {
    if (!_hasToken) {
      return;
    }
    if (isLoading.value || !_hasMore) {
      return;
    }
    isLoading.value = true;
    try {
      var data = await _fetchInventoryPage(_page);

      if (data != null &&
          data.items.isEmpty &&
          _page == 1 &&
          !_triedRemoteFreshForCurrentRefresh) {
        _triedRemoteFreshForCurrentRefresh = true;
        final refreshRes = await _inventoryApi.inventoryRefresh(appId: appId);
        if (refreshRes.success) {
          data = await _fetchInventoryPage(_page);
        }
      }

      schemas.addAll(data?.schemas ?? const <String, ShopSchemaInfo>{});
      stickers.addAll(data?.stickers ?? const <String, dynamic>{});
      total.value = data?.total ?? total.value;
      totalPrice.value = data?.totalPrice ?? totalPrice.value;

      if (data == null || data.items.isEmpty) {
        _hasMore = false;
      } else {
        final fetchedCount = data.items.length;
        items.addAll(data.items);
        final totalCount = data.total ?? data.pager?.total;
        if (totalCount != null) {
          _hasMore = items.length < totalCount;
        } else {
          _hasMore = fetchedCount >= _inventoryPageSize;
        }
        if (_hasMore) {
          _page += 1;
        }
      }
      _saveCurrentStateToCache(_activeStateKey());
    } finally {
      isLoading.value = false;
    }
  }

  Future<InventoryResponse?> _fetchInventoryPage(int page) async {
    final res = await _fetchInventoryPageWithState(
      page: page,
      sellableOnlyFlag: sellableOnly.value,
      coolingOnlyFlag: coolingOnly.value,
    );

    if (res.success) {
      _loadedStateKeys.add(_activeStateKey());
      _lastFetchedAt = DateTime.now();
    }

    return res.datas;
  }

  Future<BaseHttpResponse<InventoryResponse>> _fetchInventoryPageWithState({
    required int page,
    required bool sellableOnlyFlag,
    required bool coolingOnlyFlag,
  }) async {
    final tagPayload = Map<String, dynamic>.from(tags)
      ..removeWhere((key, value) => value == null || value == '');
    if (priceMin.value != null) {
      tagPayload['priceMin'] = priceMin.value;
    }
    if (priceMax.value != null) {
      tagPayload['priceMax'] = priceMax.value;
    }
    return _inventoryApi.inventoryList(
      appId: appId,
      page: page,
      pageSize: _inventoryPageSize,
      field: sortField.value,
      asc: sortAsc.value,
      keywords: keywords.value.isEmpty ? null : keywords.value,
      tags: tagPayload.isEmpty ? null : tagPayload,
      itemName: itemName.value,
      canSellOnly: sellableOnlyFlag ? true : null,
      status: coolingOnlyFlag ? 4 : null,
    );
  }

  Future<void> refreshInventory() async {
    if (!_hasToken) {
      return;
    }
    _invalidateStateCache();
    await _inventoryApi.inventoryRefresh(appId: appId);
    await refreshList();
  }

  Future<void> search(String value) async {
    keywords.value = value.trim();
    itemName.value = null;
    _invalidateStateCache();
    clearSelection();
    await refreshList();
  }

  Future<void> applyFilter({
    String? field,
    bool? asc,
    double? minPrice,
    double? maxPrice,
    Map<String, dynamic>? tags,
    String? itemName,
    String? keyword,
    bool? sellableOnlyFlag,
    bool? coolingOnlyFlag,
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
    if (sellableOnlyFlag != null) {
      sellableOnly.value = sellableOnlyFlag;
    }
    if (coolingOnlyFlag != null) {
      coolingOnly.value = coolingOnlyFlag;
    }
    if (sellableOnly.value && coolingOnly.value) {
      coolingOnly.value = false;
    }
    _invalidateStateCache();
    clearSelection();
    await refreshList();
  }

  Future<void> toggleSortAsc() async {
    sortAsc.value = !sortAsc.value;
    _invalidateStateCache();
    clearSelection();
    await refreshList();
  }

  Future<void> toggleSellable() async {
    final previousKey = _activeStateKey();
    _saveCurrentStateToCache(previousKey);

    sellableOnly.value = !sellableOnly.value;
    if (sellableOnly.value) {
      coolingOnly.value = false;
    }
    final targetKey = _activeStateKey();
    clearSelection();
    if (_restoreStateFromCache(targetKey)) {
      return;
    }
    await refreshList();
  }

  Future<void> toggleCooling() async {
    final previousKey = _activeStateKey();
    _saveCurrentStateToCache(previousKey);

    coolingOnly.value = !coolingOnly.value;
    if (coolingOnly.value) {
      sellableOnly.value = false;
    }
    final targetKey = _activeStateKey();
    clearSelection();
    if (_restoreStateFromCache(targetKey)) {
      return;
    }
    await refreshList();
  }

  Future<void> changeGame(int newAppId) async {
    await _globalGameController.switchGame(newAppId);
  }

  Future<void> preloadStateBucketsIfNeeded({bool force = false}) async {
    if (!_hasToken || appId == 440) {
      return;
    }
    if (_isPreloadingStateBuckets || isLoading.value) {
      return;
    }
    final currentKey = _activeStateKey();
    _saveCurrentStateToCache(currentKey);
    final targets = <String>['all', 'sellable', 'cooling'];
    if (!force && targets.every(_stateCache.containsKey)) {
      return;
    }

    _isPreloadingStateBuckets = true;
    try {
      for (final key in targets) {
        if (!force && _stateCache.containsKey(key)) {
          continue;
        }
        final snapshot = await _buildFirstPageSnapshotForState(key);
        if (snapshot == null) {
          continue;
        }
        _stateCache[key] = snapshot;
        _loadedStateKeys.add(key);
      }
    } finally {
      _isPreloadingStateBuckets = false;
    }
  }

  Future<_InventoryStateSnapshot?> _buildFirstPageSnapshotForState(
    String key,
  ) async {
    final flags = _stateFlagsForKey(key);
    final res = await _fetchInventoryPageWithState(
      page: 1,
      sellableOnlyFlag: flags.$1,
      coolingOnlyFlag: flags.$2,
    );
    if (!res.success) {
      return null;
    }
    final fetchedAt = DateTime.now();
    final data = res.datas;
    if (data == null) {
      return _InventoryStateSnapshot(
        items: const <InventoryItem>[],
        schemas: const <String, ShopSchemaInfo>{},
        stickers: const <String, dynamic>{},
        total: 0,
        totalPrice: 0,
        page: 1,
        hasMore: false,
        lastFetchedAt: fetchedAt,
        triedRemoteFreshForCurrentRefresh: false,
      );
    }

    final fetchedCount = data.items.length;
    final totalCount = data.total ?? data.pager?.total;
    final hasMore = fetchedCount > 0
        ? (totalCount != null
              ? fetchedCount < totalCount
              : fetchedCount >= _inventoryPageSize)
        : false;

    return _InventoryStateSnapshot(
      items: List<InventoryItem>.from(data.items),
      schemas: Map<String, ShopSchemaInfo>.from(data.schemas),
      stickers: Map<String, dynamic>.from(data.stickers),
      total: data.total ?? 0,
      totalPrice: data.totalPrice ?? 0,
      page: hasMore ? 2 : 1,
      hasMore: hasMore,
      lastFetchedAt: fetchedAt,
      triedRemoteFreshForCurrentRefresh: false,
    );
  }

  bool toggleSelection(int itemId) {
    if (selectedIds.contains(itemId)) {
      selectedIds.remove(itemId);
      selectedIds.refresh();
      return true;
    }

    selectedIds.add(itemId);
    selectedIds.refresh();
    return true;
  }

  void clearSelection() {
    selectedIds.clear();
    selectedIds.refresh();
  }

  Future<BaseHttpResponse<dynamic>> submitUpShop(double price) async {
    if (!_hasToken) {
      return BaseHttpResponse(code: -1, message: 'nologin');
    }
    if (selectedIds.isEmpty) {
      return BaseHttpResponse(code: -1, message: 'no_selection');
    }
    final payload = selectedIds
        .map((id) => {'id': id, 'price': price})
        .toList();
    final res = await _shopApi.orderItemUp(appId: appId, items: payload);
    if (res.success) {
      _invalidateStateCache();
      clearSelection();
      await refreshList();
    }
    return res;
  }

  Future<BaseHttpResponse<dynamic>> submitUpShopItems(
    Map<int, double> prices,
  ) async {
    if (!_hasToken) {
      return BaseHttpResponse(code: -1, message: 'nologin');
    }
    if (prices.isEmpty) {
      return BaseHttpResponse(code: -1, message: 'empty_prices');
    }
    final payload = prices.entries
        .map((entry) => {'id': entry.key, 'price': entry.value})
        .toList();
    final res = await _shopApi.orderItemUp(appId: appId, items: payload);
    if (res.success) {
      _invalidateStateCache();
      clearSelection();
      await refreshList();
    }
    return res;
  }

  String _activeStateKey() {
    if (coolingOnly.value) {
      return 'cooling';
    }
    if (sellableOnly.value) {
      return 'sellable';
    }
    return 'all';
  }

  (bool, bool) _stateFlagsForKey(String key) {
    switch (key) {
      case 'sellable':
        return (true, false);
      case 'cooling':
        return (false, true);
      default:
        return (false, false);
    }
  }

  void _invalidateStateCache() {
    _stateCache.clear();
    _loadedStateKeys.clear();
    _isPreloadingStateBuckets = false;
  }

  void _saveCurrentStateToCache(String key) {
    if (!_loadedStateKeys.contains(key)) {
      return;
    }
    _stateCache[key] = _InventoryStateSnapshot(
      items: List<InventoryItem>.from(items),
      schemas: Map<String, ShopSchemaInfo>.from(schemas),
      stickers: Map<String, dynamic>.from(stickers),
      total: total.value,
      totalPrice: totalPrice.value,
      page: _page,
      hasMore: _hasMore,
      lastFetchedAt: _lastFetchedAt,
      triedRemoteFreshForCurrentRefresh: _triedRemoteFreshForCurrentRefresh,
    );
  }

  bool _restoreStateFromCache(String key) {
    final cached = _stateCache[key];
    if (cached == null) {
      return false;
    }
    items.assignAll(cached.items);
    schemas
      ..clear()
      ..addAll(cached.schemas);
    stickers
      ..clear()
      ..addAll(cached.stickers);
    total.value = cached.total;
    totalPrice.value = cached.totalPrice;
    _page = cached.page;
    _hasMore = cached.hasMore;
    _lastFetchedAt = cached.lastFetchedAt;
    _triedRemoteFreshForCurrentRefresh =
        cached.triedRemoteFreshForCurrentRefresh;
    return true;
  }
}
