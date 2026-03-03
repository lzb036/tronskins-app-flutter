import 'dart:async';

import 'package:get/get.dart';
import 'package:tronskins_app/api/shop_product.dart';
import 'package:tronskins_app/controllers/user/user_controller.dart';

class ShopShippingNoticeController extends GetxController {
  ShopShippingNoticeController({ApiShopProductServer? api})
    : _api = api ?? ApiShopProductServer();

  static const List<int> supportedGameIds = [730, 440, 570];

  final ApiShopProductServer _api;
  final RxMap<int, int> pendingTotalsByGame = <int, int>{}.obs;

  Worker? _loginWorker;
  Timer? _pollingTimer;
  int _requestToken = 0;
  bool _isRefreshing = false;

  bool get hasAnyPending =>
      pendingTotalsByGame.values.any((count) => count > 0);

  int pendingCount(int appId) => pendingTotalsByGame[appId] ?? 0;

  bool hasOtherPending(int currentAppId) {
    for (final gameId in supportedGameIds) {
      if (gameId == currentAppId) {
        continue;
      }
      if (pendingCount(gameId) > 0) {
        return true;
      }
    }
    return false;
  }

  Map<int, int> snapshotTotals() => {
    for (final gameId in supportedGameIds) gameId: pendingCount(gameId),
  };

  @override
  void onInit() {
    super.onInit();
    final userController = Get.find<UserController>();
    _seedZeroTotals();

    _loginWorker = ever<bool>(userController.isLoggedIn, (loggedIn) {
      if (!loggedIn) {
        _requestToken += 1;
        _stopPolling();
        _seedZeroTotals();
        return;
      }
      refreshPendingTotals();
      _startPolling();
    });

    if (userController.isLoggedIn.value) {
      refreshPendingTotals();
      _startPolling();
    }
  }

  Future<void> refreshPendingTotals() async {
    final userController = Get.find<UserController>();
    if (!userController.isLoggedIn.value) {
      _seedZeroTotals();
      return;
    }
    if (_isRefreshing) {
      return;
    }
    _isRefreshing = true;

    final requestToken = ++_requestToken;
    final next = <int, int>{};
    for (final appId in supportedGameIds) {
      try {
        final res = await _api.pendingShipmentList(
          params: {
            'appId': appId,
            'page': 1,
            'pageSize': 1,
            'field': 'time',
            'asc': false,
            'statusList': [2, 3, 9],
          },
        );
        final data = res.datas;
        final total = data?.total ?? data?.pager?.total ?? 0;
        if (total > 0) {
          next[appId] = total;
        } else if (data?.items.isNotEmpty ?? false) {
          next[appId] = 1;
        } else {
          next[appId] = 0;
        }
      } catch (_) {
        // Keep current value on transient failures to avoid badge flicker.
        next[appId] = pendingCount(appId);
      }
    }

    _isRefreshing = false;
    if (!Get.find<UserController>().isLoggedIn.value) {
      _seedZeroTotals();
      return;
    }
    if (!isClosed && requestToken == _requestToken) {
      pendingTotalsByGame.assignAll(next);
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshPendingTotals();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _seedZeroTotals() {
    pendingTotalsByGame.assignAll({
      for (final gameId in supportedGameIds) gameId: 0,
    });
  }

  @override
  void onClose() {
    _loginWorker?.dispose();
    _stopPolling();
    super.onClose();
  }
}
