import 'package:get/get.dart';
import 'package:tronskins_app/api/market.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';

class MarketDetailController extends GetxController {
  MarketDetailController({ApiMarketServer? api})
    : _api = api ?? ApiMarketServer();

  final ApiMarketServer _api;
  static const int _onSalePageSize = 20;
  static const int _transactionPageSize = 10;
  static const int _buyRequestPageSize = 20;

  late MarketItemEntity item;

  final RxList<MarketListItem> onSaleItems = <MarketListItem>[].obs;
  final RxList<MarketListItem> transactionItems = <MarketListItem>[].obs;
  final RxList<MarketPricePoint> pricePoints = <MarketPricePoint>[].obs;
  final RxMap<String, MarketUserInfo> users = <String, MarketUserInfo>{}.obs;
  final RxMap<String, MarketSchemaInfo> schemas =
      <String, MarketSchemaInfo>{}.obs;
  final RxMap<String, dynamic> stickers = <String, dynamic>{}.obs;
  final RxList<BuyRequestItem> buyRequests = <BuyRequestItem>[].obs;
  final RxMap<String, ShopUserInfo> buyUsers = <String, ShopUserInfo>{}.obs;
  final RxMap<String, ShopSchemaInfo> buySchemas =
      <String, ShopSchemaInfo>{}.obs;

  final RxBool isLoadingOnSale = false.obs;
  final RxBool isLoadingTransactions = false.obs;
  final RxBool isLoadingTrend = false.obs;
  final RxBool isLoadingBuyRequests = false.obs;

  int _onSalePage = 1;
  int _transactionPage = 1;
  bool _onSaleHasMore = true;
  bool _transactionHasMore = true;
  int _buyRequestPage = 1;
  bool _buyRequestHasMore = true;
  double? _onSaleMinPrice;
  double? _onSaleMaxPrice;
  String? _onSalePaintSeed;
  int? _onSalePaintIndex;
  double? _onSalePaintWearMin;
  double? _onSalePaintWearMax;
  String? _onSaleSortField;
  bool? _onSaleSortAsc;
  bool get onSaleHasMore => _onSaleHasMore;
  bool get transactionHasMore => _transactionHasMore;
  bool get buyRequestHasMore => _buyRequestHasMore;

  int get appId => item.appId ?? 730;
  int? get schemaId => item.schemaId ?? item.id;
  String get marketHashName => item.marketHashName ?? item.marketName ?? '';

  @override
  void onInit() {
    super.onInit();
    item = Get.arguments as MarketItemEntity;
    refreshAll();
  }

  void updateItem(MarketItemEntity next) {
    item = next;
    _onSalePage = 1;
    _transactionPage = 1;
    _buyRequestPage = 1;
    _onSaleHasMore = true;
    _transactionHasMore = true;
    _buyRequestHasMore = true;
    refreshAll();
  }

  Future<void> refreshAll() async {
    stickers.clear();
    await Future.wait([
      loadTrend(reset: true),
      loadOnSale(reset: true),
      loadTransactions(reset: true),
      loadBuyRequests(reset: true),
    ]);
  }

  Future<void> loadTrend({bool reset = false, int days = 30}) async {
    if (isLoadingTrend.value) {
      return;
    }
    isLoadingTrend.value = true;
    try {
      if (marketHashName.isEmpty) {
        pricePoints.clear();
        return;
      }
      final res = await _api.priceTrend(
        appId: appId,
        marketHashName: marketHashName,
        days: days,
        useAuth: false,
      );
      pricePoints
        ..clear()
        ..addAll(res.datas?.priceInfos ?? <MarketPricePoint>[]);
    } finally {
      isLoadingTrend.value = false;
    }
  }

  Future<void> loadOnSale({bool reset = false}) async {
    if (isLoadingOnSale.value || schemaId == null) {
      return;
    }
    if (!_onSaleHasMore && !reset) {
      return;
    }
    isLoadingOnSale.value = true;
    try {
      if (reset) {
        _onSalePage = 1;
        _onSaleHasMore = true;
        onSaleItems.clear();
      }
      final res = await _api.onSaleList(
        appId: appId,
        schemaId: schemaId!,
        page: _onSalePage,
        pageSize: _onSalePageSize,
        field: _onSaleSortField,
        asc: _onSaleSortAsc,
        minPrice: _onSaleMinPrice,
        maxPrice: _onSaleMaxPrice,
        paintSeed: _onSalePaintSeed,
        paintIndex: _onSalePaintIndex,
        paintWearMin: _onSalePaintWearMin,
        paintWearMax: _onSalePaintWearMax,
      );
      final data = res.datas;
      final fetchedCount = data?.items.length ?? 0;
      if (data == null || fetchedCount == 0) {
        _onSaleHasMore = false;
      } else {
        onSaleItems.addAll(data.items);
        _onSaleHasMore = false;
      }
      users.addAll(data?.users ?? const {});
      schemas.addAll(data?.schemas ?? const {});
      stickers.addAll(data?.stickers ?? const {});
    } finally {
      isLoadingOnSale.value = false;
    }
  }

  Future<void> applyOnSaleFilter({
    String? sortField,
    bool? sortAsc,
    double? minPrice,
    double? maxPrice,
    String? paintSeed,
    int? paintIndex,
    double? paintWearMin,
    double? paintWearMax,
  }) async {
    _onSaleSortField = sortField;
    _onSaleSortAsc = sortAsc;
    _onSaleMinPrice = minPrice;
    _onSaleMaxPrice = maxPrice;
    _onSalePaintSeed = paintSeed;
    _onSalePaintIndex = paintIndex;
    _onSalePaintWearMin = paintWearMin;
    _onSalePaintWearMax = paintWearMax;
    await loadOnSale(reset: true);
  }

  Future<void> loadTransactions({bool reset = false}) async {
    if (isLoadingTransactions.value || schemaId == null) {
      return;
    }
    if (!_transactionHasMore && !reset) {
      return;
    }
    isLoadingTransactions.value = true;
    try {
      if (reset) {
        _transactionPage = 1;
        _transactionHasMore = true;
        transactionItems.clear();
      }
      final res = await _api.transactionList(
        appId: appId,
        schemaId: schemaId!,
        page: _transactionPage,
        pageSize: _transactionPageSize,
      );
      final data = res.datas;
      final fetchedCount = data?.items.length ?? 0;
      if (data == null || fetchedCount == 0) {
        _transactionHasMore = false;
      } else {
        transactionItems.addAll(data.items);
        _transactionHasMore = false;
      }
      users.addAll(data?.users ?? const {});
      schemas.addAll(data?.schemas ?? const {});
      stickers.addAll(data?.stickers ?? const {});
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  Future<void> loadBuyRequests({bool reset = false}) async {
    if (isLoadingBuyRequests.value || schemaId == null) {
      return;
    }
    if (!_buyRequestHasMore && !reset) {
      return;
    }
    isLoadingBuyRequests.value = true;
    try {
      if (reset) {
        _buyRequestPage = 1;
        _buyRequestHasMore = true;
        buyRequests.clear();
      }
      final useAuth = UserStorage.getUserInfo() != null;
      var res = await _api.buyRequestList(
        appId: appId,
        schemaId: schemaId!,
        page: _buyRequestPage,
        pageSize: _buyRequestPageSize,
        useAuth: useAuth,
      );
      if (!res.success && useAuth) {
        res = await _api.buyRequestList(
          appId: appId,
          schemaId: schemaId!,
          page: _buyRequestPage,
          pageSize: _buyRequestPageSize,
          useAuth: false,
        );
      }
      final data = res.datas;
      final fetchedCount = data?.items.length ?? 0;
      if (data == null || fetchedCount == 0) {
        _buyRequestHasMore = false;
      } else {
        buyRequests.addAll(data.items);
        _buyRequestHasMore = false;
      }
      buyUsers.addAll(data?.users ?? const {});
      buySchemas.addAll(data?.schemas ?? const {});
    } finally {
      isLoadingBuyRequests.value = false;
    }
  }
}
