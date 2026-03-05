import 'package:get/get.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/api/model/shop/shop_models.dart';
import 'package:tronskins_app/common/storage/game_storage.dart';

class ShopOrderController extends GetxController {
  final ApiShopProductServer _api = ApiShopProductServer();
  static const int _pageSize = 20;

  final RxList<ShopOrderItem> pendingShipments = <ShopOrderItem>[].obs;
  final RxList<ShopOrderItem> waitingReceipts = <ShopOrderItem>[].obs;
  final RxList<ShopOrderItem> buyRecords = <ShopOrderItem>[].obs;
  final RxMap<String, ShopSchemaInfo> schemas = <String, ShopSchemaInfo>{}.obs;
  final RxMap<String, ShopUserInfo> users = <String, ShopUserInfo>{}.obs;

  final RxBool isLoadingPending = false.obs;
  final RxBool isLoadingWaiting = false.obs;
  final RxBool isLoadingRecords = false.obs;

  final RxString pendingKeywords = ''.obs;
  final RxString pendingSortField = 'time'.obs;
  final RxBool pendingSortAsc = false.obs;
  final Rx<DateTime?> pendingStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> pendingEndDate = Rx<DateTime?>(null);
  final RxnString pendingItemName = RxnString();
  final RxMap<String, dynamic> pendingTags = <String, dynamic>{}.obs;

  final RxString waitingKeywords = ''.obs;
  final RxString waitingSortField = 'time'.obs;
  final RxBool waitingSortAsc = false.obs;
  final Rx<DateTime?> waitingStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> waitingEndDate = Rx<DateTime?>(null);

  final RxString buyRecordKeywords = ''.obs;
  final RxString buyRecordSortField = 'time'.obs;
  final RxBool buyRecordSortAsc = false.obs;
  final Rx<DateTime?> buyRecordStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> buyRecordEndDate = Rx<DateTime?>(null);
  final RxList<int> buyRecordStatusList = <int>[].obs;

  int _pendingPage = 1;
  int _waitingPage = 1;
  int _recordPage = 1;
  bool _pendingHasMore = true;
  bool _waitingHasMore = true;
  bool _recordHasMore = true;
  bool get pendingHasMore => _pendingHasMore;
  bool get waitingHasMore => _waitingHasMore;
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

  Future<void> refreshPending() async {
    _pendingPage = 1;
    _pendingHasMore = true;
    pendingShipments.clear();
    await loadPendingShipments();
  }

  Future<void> loadPendingShipments() async {
    if (isLoadingPending.value || !_pendingHasMore) {
      return;
    }
    isLoadingPending.value = true;
    try {
      final startTime = _toUnix(pendingStartDate.value);
      final endTime = _toUnix(pendingEndDate.value);
      final tags = Map<String, dynamic>.from(pendingTags)
        ..removeWhere((key, value) => value == null || value == '');
      final res = await _api.pendingShipmentList(
        params: {
          'appId': appId,
          'page': _pendingPage,
          'pageSize': _pageSize,
          'field': pendingSortField.value,
          'asc': pendingSortAsc.value,
          'keywords': pendingKeywords.value.isEmpty
              ? null
              : pendingKeywords.value,
          'itemName': pendingItemName.value,
          'tags': tags.isEmpty ? null : tags,
          'startTime': startTime,
          'endTime': endTime,
          'statusList': [2, 3, 9],
        },
      );
      final data = res.datas;
      final fetchedCount = data?.items.length ?? 0;
      if (data == null || fetchedCount == 0) {
        _pendingHasMore = false;
      } else {
        final userMap = data.users;
        final mapped = data.items.map((order) {
          if (order.user != null) {
            return order;
          }
          final buyerKey = order.buyerId ?? '';
          final buyer = userMap[buyerKey] ?? users[buyerKey];
          return ShopOrderItem(
            raw: order.raw,
            id: order.id,
            status: order.status,
            statusName: order.statusName,
            createTime: order.createTime,
            changeTime: order.changeTime,
            price: order.price,
            totalPrice: order.totalPrice,
            nums: order.nums,
            protectionTime: order.protectionTime,
            type: order.type,
            tradeOfferId: order.tradeOfferId,
            cancelDesc: order.cancelDesc,
            buyerId: order.buyerId,
            details: order.details,
            user: buyer,
          );
        }).toList();
        pendingShipments.addAll(mapped);
        _pendingHasMore = _hasMoreData(
          fetchedCount: fetchedCount,
          accumulatedCount: pendingShipments.length,
          total: data.total,
        );
        if (_pendingHasMore) {
          _pendingPage += 1;
        }
      }
      schemas.addAll(data?.schemas ?? const {});
      users.addAll(data?.users ?? const {});
    } finally {
      isLoadingPending.value = false;
    }
  }

  Future<void> refreshWaitingReceipts() async {
    _waitingPage = 1;
    _waitingHasMore = true;
    waitingReceipts.clear();
    await loadWaitingReceipts();
  }

  Future<void> loadWaitingReceipts() async {
    if (isLoadingWaiting.value || !_waitingHasMore) {
      return;
    }
    isLoadingWaiting.value = true;
    try {
      final startTime = _toUnix(waitingStartDate.value);
      final endTime = _toUnix(waitingEndDate.value);
      final res = await _api.shopBuyReceiving(
        params: {
          'appId': appId,
          'page': _waitingPage,
          'pageSize': _pageSize,
          'field': waitingSortField.value,
          'asc': waitingSortAsc.value,
          'keywords': waitingKeywords.value.isEmpty
              ? null
              : waitingKeywords.value,
          'startTime': startTime,
          'endTime': endTime,
        },
      );
      final data = res.datas;
      final fetchedCount = data?.items.length ?? 0;
      if (data == null || fetchedCount == 0) {
        _waitingHasMore = false;
      } else {
        waitingReceipts.addAll(data.items);
        _waitingHasMore = _hasMoreData(
          fetchedCount: fetchedCount,
          accumulatedCount: waitingReceipts.length,
          total: data.total,
        );
        if (_waitingHasMore) {
          _waitingPage += 1;
        }
      }
      schemas.addAll(data?.schemas ?? const {});
      users.addAll(data?.users ?? const {});
    } finally {
      isLoadingWaiting.value = false;
    }
  }

  Future<void> refreshBuyRecords() async {
    _recordPage = 1;
    _recordHasMore = true;
    buyRecords.clear();
    await loadBuyRecords();
  }

  Future<void> loadBuyRecords() async {
    if (isLoadingRecords.value || !_recordHasMore) {
      return;
    }
    isLoadingRecords.value = true;
    try {
      final statusList = buyRecordStatusList.isEmpty
          ? <int>[-2, -1, 1, 2, 3, 4, 5, 6, 9]
          : buyRecordStatusList.toList();
      final startTime = _toUnix(buyRecordStartDate.value);
      final endTime = _toUnix(buyRecordEndDate.value);
      final res = await _api.shopBuyRecord(
        params: {
          'appId': appId,
          'page': _recordPage,
          'pageSize': _pageSize,
          'field': buyRecordSortField.value,
          'asc': buyRecordSortAsc.value,
          'keywords': buyRecordKeywords.value.isEmpty
              ? null
              : buyRecordKeywords.value,
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
        buyRecords.addAll(data.items);
        _recordHasMore = _hasMoreData(
          fetchedCount: fetchedCount,
          accumulatedCount: buyRecords.length,
          total: data.total,
        );
        if (_recordHasMore) {
          _recordPage += 1;
        }
      }
      schemas.addAll(data?.schemas ?? const {});
      users.addAll(data?.users ?? const {});
    } finally {
      isLoadingRecords.value = false;
    }
  }

  Future<void> acceptTradeOffer(String orderId) async {
    await _api.tradeofferReceipt(id: orderId);
    await refreshWaitingReceipts();
  }

  Future<void> searchPending(String value) async {
    pendingKeywords.value = value.trim();
    await refreshPending();
  }

  Future<void> togglePendingSort() async {
    pendingSortAsc.value = !pendingSortAsc.value;
    await refreshPending();
  }

  Future<void> applyPendingFilter({
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? tags,
    String? itemName,
    String? keyword,
  }) async {
    if (keyword != null) {
      pendingKeywords.value = keyword.trim();
    }
    pendingStartDate.value = startDate;
    pendingEndDate.value = endDate;
    if (tags != null) {
      pendingTags.value = Map<String, dynamic>.from(tags);
    }
    if (itemName != null) {
      pendingItemName.value = itemName.isEmpty ? null : itemName;
    }
    await refreshPending();
  }

  Future<void> searchWaiting(String value) async {
    waitingKeywords.value = value.trim();
    await refreshWaitingReceipts();
  }

  Future<void> toggleWaitingSort() async {
    waitingSortAsc.value = !waitingSortAsc.value;
    await refreshWaitingReceipts();
  }

  Future<void> applyWaitingFilter({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    waitingStartDate.value = startDate;
    waitingEndDate.value = endDate;
    await refreshWaitingReceipts();
  }

  Future<void> searchBuyRecords(String value) async {
    buyRecordKeywords.value = value.trim();
    await refreshBuyRecords();
  }

  Future<void> toggleBuyRecordSort() async {
    buyRecordSortAsc.value = !buyRecordSortAsc.value;
    await refreshBuyRecords();
  }

  Future<void> applyBuyRecordFilter({
    List<int>? statusList,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    buyRecordStatusList.assignAll(statusList ?? <int>[]);
    buyRecordStartDate.value = startDate;
    buyRecordEndDate.value = endDate;
    await refreshBuyRecords();
  }

  int? _toUnix(DateTime? date) {
    if (date == null) {
      return null;
    }
    return (date.millisecondsSinceEpoch / 1000).floor();
  }
}
