import 'package:get_storage/get_storage.dart';

class SessionStorage {
  SessionStorage._();

  static const String _webIdKey = 'app_webid';
  static final GetStorage _box = GetStorage();

  static String? getWebId() {
    final raw = _box.read<String>(_webIdKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw.trim();
  }

  static void setWebId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _box.write(_webIdKey, trimmed);
  }

  static void clearWebId() {
    _box.remove(_webIdKey);
  }
}
