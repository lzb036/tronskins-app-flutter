import 'package:get_storage/get_storage.dart';

class MarketSearchHistoryStorage {
  MarketSearchHistoryStorage._();

  static const String _historyKey = 'es_query_history';
  static const int _maxItems = 15;
  static final GetStorage _box = GetStorage();

  static List<String> getHistory() {
    final raw = _box.read<List<dynamic>>(_historyKey);
    if (raw == null) return [];
    return raw
        .whereType<dynamic>()
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  static Future<void> addHistory(String keyword) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) return;
    final list = getHistory();
    list.removeWhere((item) => item.toLowerCase() == normalized.toLowerCase());
    list.insert(0, normalized);
    if (list.length > _maxItems) {
      list.removeRange(_maxItems, list.length);
    }
    await _box.write(_historyKey, list);
  }

  static Future<void> clearHistory() async {
    await _box.remove(_historyKey);
  }
}
