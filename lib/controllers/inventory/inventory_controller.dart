import 'package:get/get.dart';
import 'package:tronskins_app/api/inventory.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/common/events/app_events.dart';
import 'package:tronskins_app/common/http/interceptors/auth_interceptor.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';

class InventoryController extends GetxController {
  final ApiInventoryServer _inventoryApi = ApiInventoryServer();
  final ApiShopProductServer _shopApi = ApiShopProductServer();

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
  Worker? _logoutWorker;
  DateTime? _lastFetchedAt;
  bool _triedRemoteFreshForCurrentRefresh = false;

  static const Duration _refreshThreshold = Duration(minutes: 5);

  final RxInt currentAppId = GameStorage.getGameType().obs;
  int get appId => currentAppId.value;
  bool get _hasToken => AuthInterceptor.hasToken;

  @override
  void onInit() {
    super.onInit();
    _logoutWorker = ever(AppEvents.userLogoutEvent, (_) {
      items.clear();
      schemas.clear();
      stickers.clear();
      total.value = 0;
      totalPrice.value = 0;
      selectedIds.clear();
      itemName.value = null;
      tags.clear();
      _page = 1;
      _hasMore = true;
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
    super.onClose();
  }

  Future<void> refreshList() async {
    if (!_hasToken) {
      items.clear();
      schemas.clear();
      stickers.clear();
      total.value = 0;
      totalPrice.value = 0;
      _lastFetchedAt = null;
      return;
    }
    _page = 1;
    _hasMore = true;
    _triedRemoteFreshForCurrentRefresh = false;
    items.clear();
    await loadMore();
  }

  Future<void> refreshByPullDown() async {
    sellableOnly.value = false;
    coolingOnly.value = false;
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
        items.addAll(data.items);
        _page += 1;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<InventoryResponse?> _fetchInventoryPage(int page) async {
    final tagPayload = Map<String, dynamic>.from(tags)
      ..removeWhere((key, value) => value == null || value == '');
    if (priceMin.value != null) {
      tagPayload['priceMin'] = priceMin.value;
    }
    if (priceMax.value != null) {
      tagPayload['priceMax'] = priceMax.value;
    }

    final res = await _inventoryApi.inventoryList(
      appId: appId,
      page: page,
      pageSize: 20,
      field: sortField.value,
      asc: sortAsc.value,
      keywords: keywords.value.isEmpty ? null : keywords.value,
      tags: tagPayload.isEmpty ? null : tagPayload,
      itemName: itemName.value,
      canSellOnly: sellableOnly.value ? true : null,
      status: coolingOnly.value ? 4 : null,
    );

    if (res.success) {
      _lastFetchedAt = DateTime.now();
    }

    return res.datas;
  }

  Future<void> refreshInventory() async {
    if (!_hasToken) {
      return;
    }
    await _inventoryApi.inventoryRefresh(appId: appId);
    await refreshList();
  }

  Future<void> search(String value) async {
    keywords.value = value.trim();
    itemName.value = null;
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
    clearSelection();
    await refreshList();
  }

  Future<void> toggleSortAsc() async {
    sortAsc.value = !sortAsc.value;
    clearSelection();
    await refreshList();
  }

  Future<void> toggleSellable() async {
    sellableOnly.value = !sellableOnly.value;
    if (sellableOnly.value) {
      coolingOnly.value = false;
    }
    clearSelection();
    await refreshList();
  }

  Future<void> toggleCooling() async {
    coolingOnly.value = !coolingOnly.value;
    if (coolingOnly.value) {
      sellableOnly.value = false;
    }
    clearSelection();
    await refreshList();
  }

  Future<void> changeGame(int newAppId) async {
    if (newAppId == currentAppId.value) {
      return;
    }
    currentAppId.value = newAppId;
    await GameStorage.setGameType(newAppId);
    tags.clear();
    itemName.value = null;
    clearSelection();
    await refreshList();
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
      clearSelection();
      await refreshList();
    }
    return res;
  }
}
