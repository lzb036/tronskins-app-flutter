import 'package:get_storage/get_storage.dart';

class GameStorage {
  GameStorage._();

  static final GetStorage _box = GetStorage();
  static const String _gameTypeKey = 'es_game_type';

  static int getGameType() {
    final raw = _box.read(_gameTypeKey);
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw) ?? 730;
    }
    return 730;
  }

  static Future<void> setGameType(int appId) async {
    await _box.write(_gameTypeKey, appId);
  }
}
