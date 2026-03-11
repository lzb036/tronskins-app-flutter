class MarketNameSuggestion {
  final int? id;
  final String? marketName;
  final String? marketHashName;

  const MarketNameSuggestion({this.id, this.marketName, this.marketHashName});

  factory MarketNameSuggestion.fromJson(Map<String, dynamic> json) {
    return MarketNameSuggestion(
      id: _asInt(json['id']),
      marketName: json['market_name']?.toString(),
      marketHashName: json['market_hash_name']?.toString(),
    );
  }

  String get displayName => marketName ?? marketHashName ?? '';
}

class MarketAttributePayload {
  final Map<String, dynamic> raw;

  const MarketAttributePayload({required this.raw});

  factory MarketAttributePayload.fromJson(Map<String, dynamic> json) {
    return MarketAttributePayload(raw: json);
  }

  Map<String, dynamic> get data {
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    final list = raw['list'];
    if (list is Map<String, dynamic>) {
      return list;
    }
    return raw;
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
