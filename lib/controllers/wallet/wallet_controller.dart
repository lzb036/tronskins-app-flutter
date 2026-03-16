import 'package:get/get.dart';
import 'package:tronskins_app/api/loginServer.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/api/wallet.dart';
import 'package:tronskins_app/api/model/entity/user/user_info_entity.dart';
import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/common/storage/twofa_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';

class WalletController extends GetxController {
  WalletController({
    ApiWalletServer? api,
    ApiLoginServer? userApi,
    ApiShopProductServer? shopApi,
  }) : _api = api ?? ApiWalletServer(),
       _userApi = userApi ?? ApiLoginServer(),
       _shopApi = shopApi ?? ApiShopProductServer();

  final ApiWalletServer _api;
  final ApiLoginServer _userApi;
  final ApiShopProductServer _shopApi;

  final Rx<UserInfoEntity?> userInfo = Rx<UserInfoEntity?>(null);
  final RxBool isLoadingUser = false.obs;

  final RxList<WalletFundFlowItem> fundFlows = <WalletFundFlowItem>[].obs;
  final RxBool isLoadingFundFlows = false.obs;
  int _fundFlowPage = 1;
  bool _fundFlowHasMore = true;
  bool get hasMoreFundFlows => _fundFlowHasMore;

  final RxList<WalletLockedItem> lockedItems = <WalletLockedItem>[].obs;
  final RxBool isLoadingLocked = false.obs;
  int _lockedPage = 1;
  bool _lockedHasMore = true;
  final Set<String> _lockedSeenKeys = <String>{};
  bool get hasMoreLocked => _lockedHasMore;

  final RxList<WalletRechargeRecord> rechargeRecords =
      <WalletRechargeRecord>[].obs;
  final RxBool isLoadingRechargeRecords = false.obs;
  int _rechargePage = 1;
  bool _rechargeHasMore = true;
  bool get hasMoreRechargeRecords => _rechargeHasMore;

  final RxList<WalletWithdrawRecord> withdrawRecords =
      <WalletWithdrawRecord>[].obs;
  final RxBool isLoadingWithdrawRecords = false.obs;
  int _withdrawPage = 1;
  bool _withdrawHasMore = true;
  bool get hasMoreWithdrawRecords => _withdrawHasMore;

  final RxList<WalletIntegralRecord> integralRecords =
      <WalletIntegralRecord>[].obs;
  final RxBool isLoadingIntegralRecords = false.obs;
  int _integralPage = 1;
  bool _integralHasMore = true;
  bool get hasMoreIntegralRecords => _integralHasMore;

  final RxList<WalletSettlementRecord> settlementRecords =
      <WalletSettlementRecord>[].obs;
  final RxMap<String, WalletSchemaInfo> settlementSchemas =
      <String, WalletSchemaInfo>{}.obs;
  final RxMap<String, dynamic> settlementUsers = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> settlementStickers = <String, dynamic>{}.obs;
  final RxBool isLoadingSettlement = false.obs;
  int _settlementPage = 1;
  bool _settlementHasMore = true;
  bool get hasMoreSettlementRecords => _settlementHasMore;

  final RxList<WalletWithdrawAddress> withdrawAddresses =
      <WalletWithdrawAddress>[].obs;
  final Rxn<WalletWithdrawAddress> selectedWithdrawAddress =
      Rxn<WalletWithdrawAddress>();
  final RxBool isLoadingAddresses = false.obs;

  final RxDouble withdrawFee = 0.0.obs;
  final RxBool isLoadingWithdrawFee = false.obs;

  final Rxn<WalletOfficialWallet> officialWallet = Rxn<WalletOfficialWallet>();
  final RxBool isLoadingOfficialWallet = false.obs;

  final Rxn<WalletShopEnableStatus> shopEnableStatus =
      Rxn<WalletShopEnableStatus>();

  @override
  void onInit() {
    super.onInit();
    userInfo.value = UserStorage.getUserInfo();
  }

  Future<void> refreshUser({bool showLoading = false}) async {
    if (isLoadingUser.value && showLoading) {
      return;
    }
    if (showLoading) {
      isLoadingUser.value = true;
    }
    try {
      final res = await _userApi.getUserApi();
      if (res.success && res.datas != null) {
        final cachedUserInfo = UserStorage.getUserInfo();
        final serverUserInfo = res.datas!;
        final currentUserId = serverUserInfo.id ?? cachedUserInfo?.id ?? '';

        // 如果服务器返回的 appUse 为空，尝试从 2FA token 中推导
        String? derivedAppUse;
        if (currentUserId.isNotEmpty &&
            (serverUserInfo.appUse == null || serverUserInfo.appUse!.isEmpty)) {
          final tokens = await TwoFactorStorage.getList();
          final sameUserTokens = tokens
              .where((token) =>
                  token.userId == currentUserId &&
                  token.secret.isNotEmpty)
              .toList();
          if (sameUserTokens.length == 1) {
            derivedAppUse = sameUserTokens.first.appUse;
          }
        }

        // 合并用户信息，appUse 优先级：服务器返回 > 缓存 > 从 token 推导
        final finalAppUse = serverUserInfo.appUse?.isNotEmpty == true
            ? serverUserInfo.appUse
            : (cachedUserInfo?.appUse?.isNotEmpty == true
                ? cachedUserInfo?.appUse
                : derivedAppUse);

        final mergedUserInfo = serverUserInfo.copyWith(
          appUse: finalAppUse,
        );

        userInfo.value = mergedUserInfo;
        UserStorage.setUserInfo(mergedUserInfo);
        if (Get.isRegistered<UserController>()) {
          await Get.find<UserController>().fetchUserData(showLoading: false);
        }
      }
    } finally {
      isLoadingUser.value = false;
    }
  }

  Future<void> loadFundFlows({bool reset = false}) async {
    const pageSize = 20;
    if (isLoadingFundFlows.value) {
      return;
    }
    if (!_fundFlowHasMore && !reset) {
      return;
    }
    isLoadingFundFlows.value = true;
    try {
      if (reset) {
        _fundFlowPage = 1;
        _fundFlowHasMore = true;
        fundFlows.clear();
      }
      final res = await _api.fundChangesList(
        page: _fundFlowPage,
        pageSize: pageSize,
      );
      final data = res.datas;
      final list = data?.list ?? <WalletFundFlowItem>[];
      if (list.isEmpty) {
        _fundFlowHasMore = false;
      } else {
        fundFlows.addAll(list);
        _fundFlowHasMore = _hasMoreByPager(
          pager: data?.pager,
          accumulatedCount: fundFlows.length,
          fetchedCount: list.length,
          pageSize: pageSize,
        );
        if (_fundFlowHasMore) {
          _fundFlowPage += 1;
        }
      }
    } finally {
      isLoadingFundFlows.value = false;
    }
  }

  Future<void> loadLockedFunds({bool reset = false}) async {
    const pageSize = 20;
    if (isLoadingLocked.value) {
      return;
    }
    if (!_lockedHasMore && !reset) {
      return;
    }
    isLoadingLocked.value = true;
    try {
      if (reset) {
        _lockedPage = 1;
        _lockedHasMore = true;
        _lockedSeenKeys.clear();
        lockedItems.clear();
      }
      final res = await _api.lockingFundList(
        page: _lockedPage,
        pageSize: pageSize,
      );
      final list = res.datas ?? <WalletLockedItem>[];
      if (list.isEmpty) {
        _lockedHasMore = false;
      } else {
        final uniqueItems = list.where((item) {
          final key = _lockedItemKey(item);
          return _lockedSeenKeys.add(key);
        }).toList();

        if (uniqueItems.isEmpty) {
          // Backend may return duplicate pages endlessly; stop loading.
          _lockedHasMore = false;
          return;
        }

        lockedItems.addAll(uniqueItems);
        _lockedPage += 1;

        if (list.length < pageSize) {
          _lockedHasMore = false;
        }
      }
    } finally {
      isLoadingLocked.value = false;
    }
  }

  String _lockedItemKey(WalletLockedItem item) {
    final id = item.id?.toString();
    if (id != null && id.isNotEmpty) {
      return id;
    }
    return [
      item.lockType?.toString() ?? '',
      item.lockAmount?.toString() ?? '',
      item.createTime?.toString() ?? '',
      item.amount?.toString() ?? '',
      item.giftAmount?.toString() ?? '',
    ].join('|');
  }

  Future<WalletLockedDetail?> loadLockedDetail({
    required String id,
    int? lockType,
  }) async {
    final res = await _api.lockingFundDetail(id: id, lockType: lockType);
    if (res.success) {
      return res.datas;
    }
    return null;
  }

  Future<void> loadRechargeRecords({bool reset = false}) async {
    const pageSize = 20;
    if (isLoadingRechargeRecords.value) {
      return;
    }
    if (!_rechargeHasMore && !reset) {
      return;
    }
    isLoadingRechargeRecords.value = true;
    try {
      if (reset) {
        _rechargePage = 1;
        _rechargeHasMore = true;
        rechargeRecords.clear();
      }
      final res = await _api.rechargeRecords(
        page: _rechargePage,
        pageSize: pageSize,
      );
      final data = res.datas;
      final list = data?.list ?? <WalletRechargeRecord>[];
      if (list.isEmpty) {
        _rechargeHasMore = false;
      } else {
        rechargeRecords.addAll(list);
        _rechargeHasMore = _hasMoreByPager(
          pager: data?.pager,
          accumulatedCount: rechargeRecords.length,
          fetchedCount: list.length,
          pageSize: pageSize,
        );
        if (_rechargeHasMore) {
          _rechargePage += 1;
        }
      }
    } finally {
      isLoadingRechargeRecords.value = false;
    }
  }

  Future<void> loadWithdrawRecords({bool reset = false}) async {
    const pageSize = 20;
    if (isLoadingWithdrawRecords.value) {
      return;
    }
    if (!_withdrawHasMore && !reset) {
      return;
    }
    isLoadingWithdrawRecords.value = true;
    try {
      if (reset) {
        _withdrawPage = 1;
        _withdrawHasMore = true;
        withdrawRecords.clear();
      }
      final res = await _api.withdrawRecords(
        page: _withdrawPage,
        pageSize: pageSize,
      );
      final data = res.datas;
      final list = data?.list ?? <WalletWithdrawRecord>[];
      if (list.isEmpty) {
        _withdrawHasMore = false;
      } else {
        withdrawRecords.addAll(list);
        _withdrawHasMore = _hasMoreByPager(
          pager: data?.pager,
          accumulatedCount: withdrawRecords.length,
          fetchedCount: list.length,
          pageSize: pageSize,
        );
        if (_withdrawHasMore) {
          _withdrawPage += 1;
        }
      }
    } finally {
      isLoadingWithdrawRecords.value = false;
    }
  }

  Future<void> loadIntegralRecords({bool reset = false}) async {
    const pageSize = 20;
    if (isLoadingIntegralRecords.value) {
      return;
    }
    if (!_integralHasMore && !reset) {
      return;
    }
    isLoadingIntegralRecords.value = true;
    try {
      if (reset) {
        _integralPage = 1;
        _integralHasMore = true;
        integralRecords.clear();
      }
      final res = await _api.integralChangesList(
        page: _integralPage,
        pageSize: pageSize,
      );
      final data = res.datas;
      final list = data?.list ?? <WalletIntegralRecord>[];
      if (list.isEmpty) {
        _integralHasMore = false;
      } else {
        integralRecords.addAll(list);
        _integralHasMore = _hasMoreByPager(
          pager: data?.pager,
          accumulatedCount: integralRecords.length,
          fetchedCount: list.length,
          pageSize: pageSize,
        );
        if (_integralHasMore) {
          _integralPage += 1;
        }
      }
    } finally {
      isLoadingIntegralRecords.value = false;
    }
  }

  Future<void> loadSettlementRecords({bool reset = false}) async {
    const pageSize = 10;
    if (isLoadingSettlement.value) {
      return;
    }
    if (!_settlementHasMore && !reset) {
      return;
    }
    isLoadingSettlement.value = true;
    try {
      if (reset) {
        _settlementPage = 1;
        _settlementHasMore = true;
        settlementRecords.clear();
        settlementSchemas.clear();
        settlementUsers.clear();
        settlementStickers.clear();
      }
      final res = await _api.settlementRecords(
        page: _settlementPage,
        pageSize: pageSize,
      );
      final data = res.datas;
      final list = data?.records ?? <WalletSettlementRecord>[];
      if (list.isEmpty) {
        _settlementHasMore = false;
      } else {
        settlementRecords.addAll(list);
        _settlementHasMore = _hasMoreByPager(
          pager: data?.pager,
          accumulatedCount: settlementRecords.length,
          fetchedCount: list.length,
          pageSize: pageSize,
        );
        if (_settlementHasMore) {
          _settlementPage += 1;
        }
      }
      settlementSchemas.addAll(data?.schemas ?? const {});
      settlementUsers.addAll(data?.users ?? const {});
      settlementStickers.addAll(data?.stickers ?? const {});
    } finally {
      isLoadingSettlement.value = false;
    }
  }

  bool _hasMoreByPager({
    required WalletPager? pager,
    required int accumulatedCount,
    required int fetchedCount,
    required int pageSize,
  }) {
    if (fetchedCount <= 0) {
      return false;
    }

    if (pager != null) {
      if (pager.total > 0) {
        return accumulatedCount < pager.total;
      }
      if (pager.pages != null && pager.pages! > 0) {
        return pager.page < pager.pages!;
      }

      final serverPageSize = pager.pageSize > 0 ? pager.pageSize : pageSize;
      return fetchedCount >= serverPageSize;
    }

    return fetchedCount >= pageSize;
  }

  Future<void> loadWithdrawAddresses() async {
    if (isLoadingAddresses.value) {
      return;
    }
    isLoadingAddresses.value = true;
    try {
      final res = await _api.withdrawWalletList();
      if (res.success) {
        final list = res.datas ?? <WalletWithdrawAddress>[];
        withdrawAddresses.assignAll(list);
        if (list.isNotEmpty) {
          selectedWithdrawAddress.value = list.first;
        }
      }
    } finally {
      isLoadingAddresses.value = false;
    }
  }

  Future<bool> addWithdrawAddress({
    required String name,
    required String account,
  }) async {
    final res = await _api.withdrawWalletAdd(name: name, account: account);
    if (res.success) {
      await loadWithdrawAddresses();
      return true;
    }
    return false;
  }

  Future<bool> removeWithdrawAddress(String id) async {
    final res = await _api.withdrawWalletRemove(id: id);
    if (res.success) {
      withdrawAddresses.removeWhere((item) => item.id == id);
      if (selectedWithdrawAddress.value?.id == id) {
        selectedWithdrawAddress.value = withdrawAddresses.isNotEmpty
            ? withdrawAddresses.first
            : null;
      }
      return true;
    }
    return false;
  }

  Future<bool> submitWithdraw({
    required double amount,
    required String account,
    String? twoFa,
  }) async {
    final res = await _api.withdrawAdd(
      amount: amount,
      account: account,
      twoFa: twoFa,
    );
    if (res.success) {
      await refreshUser();
      return true;
    }
    return false;
  }

  Future<bool> cancelWithdraw(String id) async {
    final res = await _api.withdrawCancel(id: id);
    if (res.success) {
      return true;
    }
    return false;
  }

  Future<void> loadWithdrawFee() async {
    if (isLoadingWithdrawFee.value) {
      return;
    }
    isLoadingWithdrawFee.value = true;
    try {
      final res = await _shopApi.getSysParams();
      if (res.success) {
        final data = res.datas;
        final fee = data?['withdrawFeeAmount'];
        if (fee is num) {
          withdrawFee.value = fee.toDouble();
        } else {
          withdrawFee.value = double.tryParse(fee?.toString() ?? '') ?? 0;
        }
      }
    } finally {
      isLoadingWithdrawFee.value = false;
    }
  }

  Future<void> loadOfficialWallet() async {
    if (isLoadingOfficialWallet.value) {
      return;
    }
    isLoadingOfficialWallet.value = true;
    try {
      var res = await _api.officialWalletAssign();
      if (!res.success) {
        res = await _api.officialWalletGet();
      }
      if (res.success) {
        officialWallet.value = res.datas;
      }
    } finally {
      isLoadingOfficialWallet.value = false;
    }
  }

  Future<BaseHttpResponse<dynamic>> consumeChargeCard(String password) async {
    final res = await _api.consumeChargeCard(password: password);
    if (res.success) {
      await refreshUser();
    }
    return res;
  }

  Future<WalletShopEnableStatus?> fetchShopEnableStatus() async {
    final res = await _api.shopEnableStatus();
    if (res.success) {
      shopEnableStatus.value = res.datas;
    }
    return res.datas;
  }

  Future<bool?> checkWithdrawEnable() async {
    try {
      final res = await _api.withdrawCheck();
      if (res.success) {
        return res.datas == true;
      }
    } catch (_) {}
    return null;
  }

  Future<bool?> checkRechargeEnable() async {
    try {
      final res = await _api.rechargeCheck();
      if (res.success) {
        return res.datas == true;
      }
    } catch (_) {}
    return null;
  }
}
