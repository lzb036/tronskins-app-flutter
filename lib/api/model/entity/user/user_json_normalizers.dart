double? nullableDoubleFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

int? nullableIntFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

bool? nullableBoolFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return null;
}

String? nullableStringFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return value.toString();
}

Map<String, dynamic> normalizeJsonFieldTypes(
  Map<String, dynamic> json, {
  Iterable<String> stringKeys = const <String>[],
  Iterable<String> intKeys = const <String>[],
  Iterable<String> doubleKeys = const <String>[],
  Iterable<String> boolKeys = const <String>[],
}) {
  final normalized = Map<String, dynamic>.from(json);

  for (final key in stringKeys) {
    normalized[key] = nullableStringFromJson(normalized[key]);
  }
  for (final key in intKeys) {
    normalized[key] = nullableIntFromJson(normalized[key]);
  }
  for (final key in doubleKeys) {
    normalized[key] = nullableDoubleFromJson(normalized[key]);
  }
  for (final key in boolKeys) {
    normalized[key] = nullableBoolFromJson(normalized[key]);
  }

  return normalized;
}
