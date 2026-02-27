import 'package:get_storage/get_storage.dart';

class ServerStorage {
  ServerStorage._();

  //static const String defaultServer = 'https://www.etopmarket.com/'
  static const String defaultServer = 'https://www.tronskins.com/';
  static const String _serverKey = 'es_server';
  static const String _serverListKey = 'es_server_list';
  static final GetStorage _box = GetStorage();

  static String getServer() {
    final raw = _box.read<String>(_serverKey);
    if (raw == null || raw.isEmpty) {
      return defaultServer;
    }
    return _normalize(raw);
  }

  static void setServer(String server) {
    _box.write(_serverKey, _normalize(server));
  }

  static List<String> getServerList() {
    final raw = _box.read<List<dynamic>>(_serverListKey);
    if (raw == null || raw.isEmpty) {
      return [defaultServer];
    }
    return raw.map((e) => _normalize(e.toString())).toSet().toList();
  }

  static void setServerList(List<String> list) {
    final normalized = list.map(_normalize).toSet().toList();
    if (normalized.isEmpty) {
      normalized.add(defaultServer);
    }
    _box.write(_serverListKey, normalized);
  }

  static String _normalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return defaultServer;
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }
}
