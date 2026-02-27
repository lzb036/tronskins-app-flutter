import 'package:get_storage/get_storage.dart';
import 'package:tronskins_app/common/security/secure_storage.dart';

class SteamStorage {
  SteamStorage._();

  static final GetStorage _box = GetStorage();
  static const String _accountKey = 'steam_account';
  static const String _passwordKey = 'steam_password';

  static String? getAccount() {
    final raw = _box.read(_accountKey);
    return raw?.toString();
  }

  static Future<void> setAccount(String? value) async {
    if (value == null || value.isEmpty) {
      await _box.remove(_accountKey);
      return;
    }
    await _box.write(_accountKey, value);
  }

  static Future<String?> getPassword() async {
    return SecureStorage.getItem(_passwordKey);
  }

  static Future<void> setPassword(String? value) async {
    if (value == null || value.isEmpty) {
      await SecureStorage.removeItem(_passwordKey);
      return;
    }
    await SecureStorage.setItem(_passwordKey, value);
  }

  static Future<void> clear() async {
    await _box.remove(_accountKey);
    await SecureStorage.removeItem(_passwordKey);
  }
}
