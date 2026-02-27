import 'package:get_storage/get_storage.dart';
import 'package:tronskins_app/common/http/interceptors/auth_interceptor.dart';

class AppCache {
  AppCache._();

  static const _deviceIdKey = 'device_udid';
  static const _serverKey = 'es_server';
  static const _serverListKey = 'es_server_list';
  static const _gameTypeKey = 'es_game_type';
  static const _currencyKey = 'selected_currency';
  static const _twoFaListSecureKey = 'secure_es_2fa_list';

  static Future<void> clearOnLogout({bool preservePreferences = true}) async {
    final box = GetStorage();
    final preserved = <String, dynamic>{};

    if (preservePreferences) {
      final deviceId = box.read(_deviceIdKey);
      if (deviceId != null) preserved[_deviceIdKey] = deviceId;

      final server = box.read(_serverKey);
      if (server != null) preserved[_serverKey] = server;

      final serverList = box.read(_serverListKey);
      if (serverList != null) preserved[_serverListKey] = serverList;

      final gameType = box.read(_gameTypeKey);
      if (gameType != null) preserved[_gameTypeKey] = gameType;

      final currency = box.read(_currencyKey);
      if (currency != null) preserved[_currencyKey] = currency;

      final twoFaList = box.read(_twoFaListSecureKey);
      if (twoFaList != null) preserved[_twoFaListSecureKey] = twoFaList;
    }

    await AuthInterceptor.clearToken();
    await box.erase();

    if (!preservePreferences) {
      try {
        await GetStorage('theme').erase();
      } catch (_) {}
      try {
        await GetStorage('language').erase();
      } catch (_) {}
    }

    if (preservePreferences) {
      for (final entry in preserved.entries) {
        await box.write(entry.key, entry.value);
      }
    }
  }
}
