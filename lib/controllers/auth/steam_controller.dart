import 'package:get/get.dart';
import 'package:tronskins_app/api/loginServer.dart';
import 'package:tronskins_app/api/steam.dart';
import 'package:tronskins_app/api/model/entity/user/user_steam_config_entity.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';
import 'package:tronskins_app/common/utils/steam_cookie_helper.dart';

class SteamController extends GetxController {
  final ApiSteamServer _steamApi = ApiSteamServer();
  final ApiLoginServer _userApi = ApiLoginServer();

  final Rx<UserSteamConfigEntity?> config = Rx<UserSteamConfigEntity?>(null);
  final RxString userNickname = ''.obs;
  final RxString tradeUrl = ''.obs;
  final RxString apiKey = ''.obs;
  final RxnBool tradeStatus = RxnBool();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool sessionValid = true.obs;

  String _initialTradeUrl = '';
  String _initialApiKey = '';
  Future<void>? _loadFuture;

  bool get hasSteamBound => config.value?.steamId?.isNotEmpty == true;
  bool get hasChanges =>
      tradeUrl.value.trim() != _initialTradeUrl ||
      apiKey.value.trim() != _initialApiKey;

  @override
  void onInit() {
    super.onInit();
    loadSteamConfig();
  }

  Future<void> loadSteamConfig({bool refreshUser = true}) async {
    final existing = _loadFuture;
    if (existing != null) {
      return existing;
    }

    final future = _doLoadSteamConfig();
    _loadFuture = future;
    future.whenComplete(() {
      if (identical(_loadFuture, future)) {
        _loadFuture = null;
      }
    });
    return future;
  }

  Future<void> _doLoadSteamConfig() async {
    isLoading.value = true;
    try {
      final res = await _userApi.getUserApi();
      if (res.success && res.datas?.config != null) {
        final nextConfig = res.datas!.config;
        userNickname.value = (res.datas?.nickname ?? '').trim();
        _initialTradeUrl = nextConfig?.tradeUrl ?? '';
        _initialApiKey = nextConfig?.sensitiveAccessKey ?? '';
        tradeUrl.value = _initialTradeUrl;
        apiKey.value = _initialApiKey;
        config.value = nextConfig;
      } else {
        config.value = null;
        userNickname.value = '';
        _initialTradeUrl = '';
        _initialApiKey = '';
        tradeUrl.value = '';
        apiKey.value = '';
      }
      await refreshTradeStatus();
      await checkSession();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshTradeStatus() async {
    try {
      tradeStatus.value = null;
      final res = await _steamApi.steamTradingState();
      tradeStatus.value = res.success ? (res.datas ?? false) : false;
    } catch (_) {
      tradeStatus.value = false;
    }
  }

  Future<void> checkSession() async {
    try {
      final res = await _steamApi.steamOnlineState();
      sessionValid.value = res.success ? (res.datas ?? false) : false;
    } catch (_) {
      sessionValid.value = false;
    }
  }

  Future<void> saveChanges() async {
    if (!hasChanges || isSaving.value) {
      return;
    }
    isSaving.value = true;
    try {
      final urlValue = tradeUrl.value.trim();
      final keyValue = apiKey.value.trim();

      if (urlValue.isNotEmpty && urlValue != _initialTradeUrl) {
        await _steamApi.setTradeUrl(tradeUrl: urlValue);
        _initialTradeUrl = urlValue;
      }
      if (keyValue.isNotEmpty && keyValue != _initialApiKey) {
        await _steamApi.setApiKey(accessKey: keyValue);
        _initialApiKey = keyValue;
      }
    } finally {
      isSaving.value = false;
    }
  }

  Future<String?> getTemporaryToken() async {
    final res = await _steamApi.getTemporaryToken();
    if (res.success && res.datas != null && res.datas!.isNotEmpty) {
      return res.datas;
    }
    return null;
  }

  Future<BaseHttpResponse<String>> canUnbind() => _steamApi.steamUnbindCheck();

  /// Check Steam cookie/session status
  /// Returns true if session is valid, false otherwise
  Future<bool> checkSteamCookie() async {
    final steamId = config.value?.steamId;
    if (steamId == null || steamId.isEmpty) {
      return false;
    }

    try {
      final cookieInfo = await SteamCookieHelper.getSteamInfo(steamId);
      if (cookieInfo?.status == true) {
        return true;
      }

      // If account inconsistent, show warning
      if (cookieInfo?.isLoginSteam == true) {
        return false;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Get detailed Steam cookie info
  Future<SteamCookieInfo?> getSteamCookieInfo() async {
    final steamId = config.value?.steamId;
    if (steamId == null || steamId.isEmpty) {
      return null;
    }
    return await SteamCookieHelper.getSteamInfo(steamId);
  }
}
