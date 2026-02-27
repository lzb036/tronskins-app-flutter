import 'package:get/get.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';

class ShopSalesController extends GetxController {
  final ApiShopProductServer _api = ApiShopProductServer();

  final RxList<ShopItemAsset> onSaleItems = <ShopItemAsset>[].obs;
  final RxList<ShopOrderItem> sellRecords = <ShopOrderItem>[].obs;
  final RxMap<String, ShopSchemaInfo> schemas = <String, ShopSchemaInfo>{}.obs;
  final RxMap<String, ShopUserInfo> users = <String, ShopUserInfo>{}.obs;
  final RxInt totalOnSale = 0.obs;
  final RxDouble totalOnSalePrice = 0.0.obs;
  final RxString onSaleKeywords = ''.obs;
  final RxString onSaleSortField = 'price'.obs;
  final RxBool onSaleSortAsc = false.obs;
  final RxnDouble onSalePriceMin = RxnDouble();
  final RxnDouble onSalePriceMax = RxnDouble();

  final RxString recordKeywords = ''.obs;
  final RxString recordSortField = 'time'.obs;
  final RxBool recordSortAsc = false.obs;
  final Rx<DateTime?> recordStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> recordEndDate = Rx<DateTime?>(null);
  final RxList<int> recordStatusList = <int>[].obs;

  final RxBool isLoadingOnSale = false.obs;
  final RxBool isLoadingRecords = false.obs;

  int _onSalePage = 1;
  int _recordPage = 1;
  bool _onSaleHasMore = true;
  bool _recordHasMore = true;

  int get appId => GameStorage.getGameType();

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
      final tags = <String, dynamic>{};
      if (onSalePriceMin.value != null) {
        tags['priceMin'] = onSalePriceMin.value;
      }
      if (onSalePriceMax.value != null) {
        tags['priceMax'] = onSalePriceMax.value;
      }
      final params = {
        'appId': appId,
        'page': _onSalePage,
        'pageSize': 20,
        'keywords': onSaleKeywords.value.isEmpty ? null : onSaleKeywords.value,
        'field': onSaleSortField.value,
        'asc': onSaleSortAsc.value,
        'tags': tags.isEmpty ? null : tags,
        'minPrice': onSalePriceMin.value,
        'maxPrice': onSalePriceMax.value,
      }..removeWhere((key, value) => value == null || value == '');
      final res = await _api.shopOnSaleList(params: params);
      final data = res.datas;
      if (data == null || data.items.isEmpty) {
        _onSaleHasMore = false;
      } else {
        onSaleItems.addAll(data.items);
        _onSalePage += 1;
      }
      totalOnSale.value = data?.total ?? totalOnSale.value;
      totalOnSalePrice.value = data?.totalPrice ?? totalOnSalePrice.value;
      schemas.addAll(data?.schemas ?? const {});
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
  }) async {
    onSaleSortField.value = sortField;
    onSaleSortAsc.value = sortAsc;
    onSalePriceMin.value = minPrice;
    onSalePriceMax.value = maxPrice;
    await refreshOnSale();
  }

  Future<void> applyRecordFilter({
    List<int>? statusList,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    recordStatusList.assignAll(statusList ?? <int>[]);
    recordStartDate.value = startDate;
    recordEndDate.value = endDate;
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
      final res = await _api.shopSellRecord(
        params: {
          'appId': appId,
          'page': _recordPage,
          'pageSize': 20,
          'field': recordSortField.value,
          'asc': recordSortAsc.value,
          'keywords':
              recordKeywords.value.isEmpty ? null : recordKeywords.value,
          'statusList': statusList,
          'startTime': startTime,
          'endTime': endTime,
        },
      );
      final data = res.datas;
      if (data == null || data.items.isEmpty) {
        _recordHasMore = false;
      } else {
        sellRecords.addAll(data.items);
        _recordPage += 1;
      }
      schemas.addAll(data?.schemas ?? const {});
      users.addAll(data?.users ?? const {});
    } finally {
      isLoadingRecords.value = false;
    }
  }

  Future<void> delistItems(List<int> ids) async {
    await _api.orderItemRemoved(ids: ids);
    await refreshOnSale();
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
