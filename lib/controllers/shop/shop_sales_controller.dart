import 'package:get/get.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';

class ShopSalesController extends GetxController {
  final ApiShopProductServer _api = ApiShopProductServer();
  static const int _pageSize = 20;

  final RxList<ShopItemAsset> onSaleItems = <ShopItemAsset>[].obs;
  final RxList<ShopOrderItem> sellRecords = <ShopOrderItem>[].obs;
  final RxMap<String, ShopSchemaInfo> schemas = <String, ShopSchemaInfo>{}.obs;
  final RxMap<String, dynamic> stickers = <String, dynamic>{}.obs;
  final RxMap<String, ShopUserInfo> users = <String, ShopUserInfo>{}.obs;
  final RxInt totalOnSale = 0.obs;
  final RxDouble totalOnSalePrice = 0.0.obs;
  final RxString onSaleKeywords = ''.obs;
  final RxString onSaleSortField = 'price'.obs;
  final RxBool onSaleSortAsc = false.obs;
  final RxnDouble onSalePriceMin = RxnDouble();
  final RxnDouble onSalePriceMax = RxnDouble();
  final RxnString onSaleItemName = RxnString();
  final RxMap<String, dynamic> onSaleTags = <String, dynamic>{}.obs;

  final RxString recordKeywords = ''.obs;
  final RxString recordSortField = 'time'.obs;
  final RxBool recordSortAsc = false.obs;
  final Rx<DateTime?> recordStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> recordEndDate = Rx<DateTime?>(null);
  final RxList<int> recordStatusList = <int>[].obs;
  final RxnString recordItemName = RxnString();
  final RxMap<String, dynamic> recordTags = <String, dynamic>{}.obs;

  final RxBool isLoadingOnSale = false.obs;
  final RxBool isLoadingRecords = false.obs;

  int _onSalePage = 1;
  int _recordPage = 1;
  bool _onSaleHasMore = true;
  bool _recordHasMore = true;
  bool get onSaleHasMore => _onSaleHasMore;
  bool get recordHasMore => _recordHasMore;

  int get appId => GameStorage.getGameType();

  bool _hasMoreData({
    required int fetchedCount,
    required int accumulatedCount,
    required int? total,
  }) {
    if (fetchedCount <= 0) {
      return false;
    }
    if (total != null && total > 0) {
      return accumulatedCount < total;
    }
    return fetchedCount >= _pageSize;
  }

  Future<void> refreshOnSale() async {
    _onSalePage = 1;
    _onSaleHasMore = true;
    onSaleItems.clear();
    totalOnSale.value = 0;
    totalOnSalePrice.value = 0;
    await loadOnSale();
  }

  Future<void> loadOnSale() async {
    if (isLoadingOnSale.value || !_onSaleHasMore) {
      return;
    }
    isLoadingOnSale.value = true;
    try {
      final tags = Map<String, dynamic>.from(onSaleTags)
        ..removeWhere((key, value) => value == null || value == '');
      if (onSalePriceMin.value != null) {
        tags['priceMin'] = onSalePriceMin.value;
      }
      if (onSalePriceMax.value != null) {
        tags['priceMax'] = onSalePriceMax.value;
      }
      final params = {
        'appId': appId,
        'page': _onSalePage,
        'pageSize': _pageSize,
        'keywords': onSaleKeywords.value.isEmpty ? null : onSaleKeywords.value,
        'field': onSaleSortField.value,
        'asc': onSaleSortAsc.value,
        'itemName': onSaleItemName.value,
        'tags': tags.isEmpty ? null : tags,
        'minPrice': onSalePriceMin.value,
        'maxPrice': onSalePriceMax.value,
      }..removeWhere((key, value) => value == null || value == '');
      final res = await _api.shopOnSaleList(params: params);
      final data = res.datas;
      final fetchedCount = data?.items.length ?? 0;
      if (data == null || fetchedCount == 0) {
        _onSaleHasMore = false;
      } else {
        onSaleItems.addAll(data.items);
        _onSaleHasMore = _hasMoreData(
          fetchedCount: fetchedCount,
          accumulatedCount: onSaleItems.length,
          total: data.total,
        );
        if (_onSaleHasMore) {
          _onSalePage += 1;
        }
      }
      totalOnSale.value = data?.total ?? totalOnSale.value;
      totalOnSalePrice.value = data?.totalPrice ?? totalOnSalePrice.value;
      schemas.addAll(data?.schemas ?? const {});
      stickers.addAll(data?.stickers ?? const {});
      users.addAll(data?.users ?? const {});
    } finally {
      isLoadingOnSale.value = false;
    }
  }

  Future<void> refreshSellRecords() async {
    _recordPage = 1;
    _recordHasMore = true;
    sellRecords.clear();
    await loadSellRecords();
  }

  Future<void> searchOnSale(String value) async {
    onSaleKeywords.value = value.trim();
    await refreshOnSale();
  }

  Future<void> searchSellRecords(String value) async {
    recordKeywords.value = value.trim();
    await refreshSellRecords();
  }

  Future<void> toggleOnSaleSort() async {
    onSaleSortAsc.value = !onSaleSortAsc.value;
    await refreshOnSale();
  }

  Future<void> toggleRecordSort() async {
    recordSortAsc.value = !recordSortAsc.value;
    await refreshSellRecords();
  }

  Future<void> applyOnSaleFilter({
    required String sortField,
    required bool sortAsc,
    double? minPrice,
    double? maxPrice,
    Map<String, dynamic>? tags,
    String? itemName,
    String? keyword,
  }) async {
    onSaleSortField.value = sortField;
    onSaleSortAsc.value = sortAsc;
    if (keyword != null) {
      onSaleKeywords.value = keyword.trim();
    }
    onSalePriceMin.value = minPrice;
    onSalePriceMax.value = maxPrice;
    if (tags != null) {
      onSaleTags.value = Map<String, dynamic>.from(tags);
    }
    if (itemName != null) {
      onSaleItemName.value = itemName.isEmpty ? null : itemName;
    }
    await refreshOnSale();
  }

  Future<void> applyRecordFilter({
    List<int>? statusList,
    DateTime? startDate,
    DateTime? endDate,
    bool? sortAsc,
    String? sortField,
    Map<String, dynamic>? tags,
    String? itemName,
    String? keyword,
  }) async {
    recordStatusList.assignAll(statusList ?? <int>[]);
    recordStartDate.value = startDate;
    recordEndDate.value = endDate;
    if (keyword != null) {
      recordKeywords.value = keyword.trim();
    }
    if (sortAsc != null) {
      recordSortAsc.value = sortAsc;
    }
    if (sortField != null && sortField.isNotEmpty) {
      recordSortField.value = sortField;
    }
    if (tags != null) {
      recordTags.value = Map<String, dynamic>.from(tags);
    }
    if (itemName != null) {
      recordItemName.value = itemName.isEmpty ? null : itemName;
    }
    await refreshSellRecords();
  }

  Future<void> loadSellRecords() async {
    if (isLoadingRecords.value || !_recordHasMore) {
      return;
    }
    isLoadingRecords.value = true;
    try {
      final statusList = recordStatusList.isEmpty
          ? <int>[-1, 1, 3, 4, 5, 6, 9]
          : recordStatusList.toList();
      final startTime = _toUnix(recordStartDate.value);
      final endTime = _toUnix(recordEndDate.value);
      final tags = Map<String, dynamic>.from(recordTags)
        ..removeWhere((key, value) => value == null || value == '');
      final res = await _api.shopSellRecord(
        params: {
          'appId': appId,
          'page': _recordPage,
          'pageSize': _pageSize,
          'field': recordSortField.value,
          'asc': recordSortAsc.value,
          'keywords': recordKeywords.value.isEmpty
              ? null
              : recordKeywords.value,
          'itemName': recordItemName.value,
          'tags': tags.isEmpty ? null : tags,
          'statusList': statusList,
          'startTime': startTime,
          'endTime': endTime,
        },
      );
      final data = res.datas;
      final fetchedCount = data?.items.length ?? 0;
      if (data == null || fetchedCount == 0) {
        _recordHasMore = false;
      } else {
        sellRecords.addAll(data.items);
        _recordHasMore = _hasMoreData(
          fetchedCount: fetchedCount,
          accumulatedCount: sellRecords.length,
          total: data.total,
        );
        if (_recordHasMore) {
          _recordPage += 1;
        }
      }
      schemas.addAll(data?.schemas ?? const {});
      stickers.addAll(data?.stickers ?? const {});
      users.addAll(data?.users ?? const {});
    } finally {
      isLoadingRecords.value = false;
    }
  }

  Future<BaseHttpResponse<dynamic>> delistItems(List<int> ids) async {
    final res = await _api.orderItemRemoved(ids: ids);
    if (res.success) {
      await refreshOnSale();
    }
    return res;
  }

  Future<void> changePrice({
    required int appId,
    required List<Map<String, dynamic>> items,
  }) async {
    await _api.orderItemChangePrice(appId: appId, items: items);
    await refreshOnSale();
  }

  int? _toUnix(DateTime? date) {
    if (date == null) {
      return null;
    }
    return (date.millisecondsSinceEpoch / 1000).floor();
  }
}
