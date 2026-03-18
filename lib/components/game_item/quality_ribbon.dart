import 'package:flutter/material.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/game_item_utils.dart';

class QualityRibbon extends StatelessWidget {
  const QualityRibbon({super.key, required this.quality});

  final TagInfo quality;
  static const double _ribbonWidth = 125; // 250rpx in legacy nvue
  static const double _horizontalPadding = 8; // 15rpx ~= 7.5
  static const double _verticalPadding = 4; // 8rpx

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(quality.color) ?? Colors.white;
    final label = quality.label ?? '';
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: _ribbonWidth,
        padding: const EdgeInsets.symmetric(
          horizontal: _horizontalPadding,
          vertical: _verticalPadding,
        ),
        alignment: Alignment.center,
        color: Colors.black.withOpacity(0.8),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
