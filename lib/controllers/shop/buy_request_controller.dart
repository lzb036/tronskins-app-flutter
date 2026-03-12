import 'package:get/get.dart';
import 'package:tronskins_app/api/shop.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';

class BuyRequestController extends GetxController {
  final ApiShopProductServer _api = ApiShopProductServer();
  final ApiShopServer _shopApi = ApiShopServer();

  final RxList<BuyRequestItem> myBuying = <BuyRequestItem>[].obs;
  final RxList<BuyRequestItem> buyRecords = <BuyRequestItem>[].obs;
  final RxMap<String, ShopSchemaInfo> schemas = <String, ShopSchemaInfo>{}.obs;
  final RxInt totalMyBuying = 0.obs;
  final RxInt totalRecords = 0.obs;

  final RxBool isLoadingMyBuying = false.obs;
  final RxBool isLoadingRecords = false.obs;
  final RxBool purchaseOnline = true.obs;
  final RxBool buyingSortAsc = false.obs;
  final RxBool recordSortAsc = false.obs;

  final RxString buyingKeywords = ''.obs;
  final RxString recordKeywords = ''.obs;
  final RxnString buyingItemName = RxnString();
  final RxMap<String, dynamic> buyingTags = <String, dynamic>{}.obs;
  final RxnString recordItemName = RxnString();
  final RxMap<String, dynamic> recordTags = <String, dynamic>{}.obs;

  int _myBuyingPage = 1;
  int _recordPage = 1;
  bool _myBuyingHasMore = true;
  bool _recordHasMore = true;
  bool get myBuyingHasMore => _myBuyingHasMore;
  bool get recordHasMore => _recordHasMore;

  String _buyingSortField = 'upTime';
  String get buyingSortField => _buyingSortField;
  bool get isBuyingSortByPrice => _buyingSortField == 'price';

  int get appId => GameStorage.getGameType();

  @override
  void onInit() {
    super.onInit();
    refreshPurchaseStatus();
  }

  Future<void> refreshPurchaseStatus() async {
    final user = UserStorage.getUserInfo();
    final uuid = user?.uuid ?? user?.shop?.uuid;
    if (uuid == null || uuid.isEmpty) {
      return;
    }
    try {
      final res = await _shopApi.getUserShopInfo(params: {'uuid': uuid});
      if (res.success && res.datas != null) {
        purchaseOnline.value = _asBool(res.datas?['signWanted']);
      }
    } catch (_) {
      // Keep previous value on failure.
    }
  }

  Future<bool> togglePurchaseStatus() async {
    final next = !purchaseOnline.value;
    purchaseOnline.value = next;
    try {
      final res = await _api.submitBuyStatus();
      if (!res.success) {
        purchaseOnline.value = !next;
        return false;
      }
      return true;
    } catch (_) {
      purchaseOnline.value = !next;
      return false;
    }
  }

  Future<void> refreshMyBuying() async {
    _myBuyingPage = 1;
    _myBuyingHasMore = true;
    myBuying.clear();
    totalMyBuying.value = 0;
    await loadMyBuying();
  }

  Future<void> loadMyBuying() async {
    if (isLoadingMyBuying.value || !_myBuyingHasMore) {
      return;
    }
    isLoadingMyBuying.value = true;
    try {
      final tags = Map<String, dynamic>.from(buyingTags)
        ..removeWhere((key, value) => value == null || value == '');
      final params = {
        'appId': appId,
        'status': 1,
        'page': _myBuyingPage,
        'pageSize': 20,
        'asc': buyingSortAsc.value,
        'field': _buyingSortField,
        'keywords': buyingKeywords.value.isEmpty ? null : buyingKeywords.value,
        'itemName': buyingItemName.value,
        'tags': tags.isEmpty ? null : tags,
      }..removeWhere((key, value) => value == null || value == '');
      final res = await _api.myBuyOrderList(params: params);
      final data = res.datas;
      if (data == null || data.items.isEmpty) {
        _myBuyingHasMore = false;
      } else {
        myBuying.addAll(data.items);
        _myBuyingPage += 1;
      }
      totalMyBuying.value = data?.pager?.total ?? data?.total ?? 0;
      schemas.addAll(data?.schemas ?? const {});
    } finally {
      isLoadingMyBuying.value = false;
    }
  }

  Future<void> refreshBuyRecords() async {
    _recordPage = 1;
    _recordHasMore = true;
    buyRecords.clear();
    totalRecords.value = 0;
    await loadBuyRecords();
  }

  Future<void> loadBuyRecords() async {
    if (isLoadingRecords.value || !_recordHasMore) {
      return;
    }
    isLoadingRecords.value = true;
    try {
      final tags = Map<String, dynamic>.from(recordTags)
        ..removeWhere((key, value) => value == null || value == '');
      final params = {
        'appId': appId,
        'page': _recordPage,
        'pageSize': 20,
        'asc': recordSortAsc.value,
        'field': 'time',
        'keywords': recordKeywords.value.isEmpty ? null : recordKeywords.value,
        'itemName': recordItemName.value,
        'tags': tags.isEmpty ? null : tags,
      }..removeWhere((key, value) => value == null || value == '');
      final res = await _api.myBuyOrderList(params: params);
      final data = res.datas;
      if (data == null || data.items.isEmpty) {
        _recordHasMore = false;
      } else {
        buyRecords.addAll(data.items);
        _recordPage += 1;
      }
      totalRecords.value = data?.pager?.total ?? data?.total ?? 0;
      schemas.addAll(data?.schemas ?? const {});
    } finally {
      isLoadingRecords.value = false;
    }
  }

  Future<void> searchMyBuying(String value) async {
    buyingKeywords.value = value.trim();
    await refreshMyBuying();
  }

  Future<void> searchRecords(String value) async {
    recordKeywords.value = value.trim();
    await refreshBuyRecords();
  }

  Future<void> togglePriceSort() async {
    _buyingSortField = 'price';
    buyingSortAsc.value = !buyingSortAsc.value;
    await refreshMyBuying();
  }

  Future<void> applyMyBuyingFilter({
    bool? sortAsc,
    String? sortField,
    Map<String, dynamic>? tags,
    String? itemName,
  }) async {
    if (sortField != null && sortField.isNotEmpty) {
      _buyingSortField = sortField;
    }
    if (sortAsc != null) {
      buyingSortAsc.value = sortAsc;
    }
    if (tags != null) {
      buyingTags.value = Map<String, dynamic>.from(tags);
    }
    if (itemName != null) {
      buyingItemName.value = itemName.isEmpty ? null : itemName;
    }
    await refreshMyBuying();
  }

  Future<void> toggleRecordSort() async {
    recordSortAsc.value = !recordSortAsc.value;
    await refreshBuyRecords();
  }

  Future<void> applyRecordFilter({
    bool? sortAsc,
    Map<String, dynamic>? tags,
    String? itemName,
  }) async {
    if (sortAsc != null) {
      recordSortAsc.value = sortAsc;
    }
    if (tags != null) {
      recordTags.value = Map<String, dynamic>.from(tags);
    }
    if (itemName != null) {
      recordItemName.value = itemName.isEmpty ? null : itemName;
    }
    await refreshBuyRecords();
  }

  Future<void> cancelBuy(String id) async {
    await _api.orderItemCancelBuy(id: id);
    await refreshMyBuying();
    await refreshBuyRecords();
  }
}

bool _asBool(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final text = value.toString().toLowerCase();
  return text == 'true' || text == '1';
}
