import 'dart:async';

import 'package:get/get.dart';
import 'package:tronskins_app/api/guard.dart';
import 'package:tronskins_app/api/model/user/guard_models.dart';
import 'package:tronskins_app/common/storage/server_storage.dart';
import 'package:tronskins_app/common/storage/twofa_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class TwoFactorController extends GetxController {
  TwoFactorController({ApiGuardServer? api}) : _api = api ?? ApiGuardServer();

  final ApiGuardServer _api;

  final RxList<TwoFactorToken> tokens = <TwoFactorToken>[].obs;
  final RxnString email = RxnString();
  final RxBool isBound = false.obs;
  final RxBool isLoading = false.obs;
  final RxInt tick = 0.obs;

  Timer? _timer;
  int _lastBindSecond = -1;

  String _normalizeText(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  String _normalizeServer(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  bool _matchesCurrentServer(
    TwoFactorToken token,
    String normalizedServer, {
    bool allowLegacy = false,
  }) {
    final tokenServer = _normalizeServer(token.server);
    if (tokenServer.isEmpty) {
      return allowLegacy;
    }
    return tokenServer == normalizedServer;
  }

  TwoFactorToken? _findCurrentUserToken({
    required String server,
    required String appUse,
    required String userId,
  }) {
    final normalizedServer = _normalizeServer(server);
    final normalizedAppUse = _normalizeText(appUse);
    final normalizedUserId = userId.trim();
    if (normalizedAppUse.isEmpty || normalizedUserId.isEmpty) {
      return null;
    }

    for (final item in tokens) {
      if (item.secret.trim().isEmpty) {
        continue;
      }
      if (item.userId.trim() == normalizedUserId &&
          _normalizeText(item.appUse) == normalizedAppUse &&
          _matchesCurrentServer(item, normalizedServer)) {
        return item;
      }
    }

    if (normalizedServer.isEmpty) {
      return null;
    }

    for (final item in tokens) {
      if (item.secret.trim().isEmpty) {
        continue;
      }
      if (item.userId.trim() == normalizedUserId &&
          _normalizeText(item.appUse) == normalizedAppUse &&
          _matchesCurrentServer(item, normalizedServer, allowLegacy: true)) {
        return item;
      }
    }

    return null;
  }

  @override
  void onInit() {
    super.onInit();
    loadTokens();
    if (UserStorage.getUserInfo() != null) {
      refreshStatus();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      tick.value++;
      _maybeBindGuard();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> loadTokens() async {
    tokens.assignAll(await TwoFactorStorage.getList());
  }

  Future<void> refreshStatus() async {
    if (isLoading.value) {
      return;
    }
    isLoading.value = true;
    try {
      final res = await _api.guardStatus();
      if (res.success) {
        final data = res.datas;
        email.value = data?.email;
        isBound.value = data?.twoFa == true;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<BaseHttpResponse<dynamic>> sendEmailCode() async {
    final value = email.value;
    if (value == null || value.isEmpty) {
      return BaseHttpResponse<dynamic>(code: -1, message: '', datas: null);
    }
    return _api.sendEmailCodeSubmit();
  }

  Future<BaseHttpResponse<dynamic>> syncToken(String emailCode) async {
    final res = await _api.guardInfo(emailCode: emailCode);
    if (res.success && res.datas != null) {
      final info = res.datas as GuardInfo;
      final appUse = info.appUse ?? '';
      final userId = info.userId ?? '';
      final secret = info.secret ?? '';
      final showEmail = info.showEmail ?? email.value ?? '';
      if (appUse.isNotEmpty && userId.isNotEmpty && secret.isNotEmpty) {
        await TwoFactorStorage.bindSecret(
          server: ServerStorage.getServer(),
          appUse: appUse,
          userId: userId,
          secret: secret,
          showEmail: showEmail,
        );
        await loadTokens();
        return res;
      }
    }
    return BaseHttpResponse<dynamic>(
      code: -1,
      message: res.message,
      datas: res.datas,
    );
  }

  Future<void> deleteToken(TwoFactorToken token) async {
    await TwoFactorStorage.removeToken(
      server: token.server,
      appUse: token.appUse,
      userId: token.userId,
    );
    await loadTokens();
  }

  String codeForToken(TwoFactorToken token) {
    return TwoFactorHelper.generateCode(token.secret);
  }

  int remainingSeconds() {
    return TwoFactorHelper.remainingSeconds();
  }

  Future<void> _maybeBindGuard() async {
    final user = UserStorage.getUserInfo();
    if (user == null || user.safeTokenStatus == true) {
      return;
    }
    final token = _findCurrentUserToken(
      server: ServerStorage.getServer(),
      appUse: user.appUse ?? '',
      userId: user.id ?? '',
    );
    if (token == null || token.secret.isEmpty) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = TwoFactorHelper.remainingSeconds();
    if (remaining == 30 && now != _lastBindSecond) {
      _lastBindSecond = now;
      final code = TwoFactorHelper.generateCode(token.secret);
      if (code.isEmpty) {
        return;
      }
      await _api.bindGuard(code: code);
      await refreshStatus();
    }
  }
}
