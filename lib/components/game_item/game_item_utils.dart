import 'package:flutter/material.dart';

Color? parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) {
    return null;
  }
  final normalized = hex.replaceAll('#', '');
  if (normalized.length == 6) {
    return Color(int.parse('FF$normalized', radix: 16));
  }
  return null;
}

Color? qualityBorderColor(String? hex) {
  if (hex == null || hex.isEmpty) {
    return null;
  }
  final normalized = hex.replaceAll('#', '').toUpperCase();
  final safe = normalized == 'D2D2D2' ? 'FFFFFF' : normalized;
  return parseHexColor(safe);
}

String rarityBgAsset(String? color) {
  final normalized = (color ?? 'b0c3d9').replaceAll('#', '').toLowerCase();
  return 'assets/images/game/item/$normalized.png';
}
