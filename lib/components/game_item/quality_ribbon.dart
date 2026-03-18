import 'package:flutter/material.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';
import 'package:tronskins_app/components/game_item/game_item_utils.dart';

class QualityRibbon extends StatelessWidget {
  const QualityRibbon({super.key, required this.quality});

  final TagInfo quality;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(quality.color) ?? Colors.white;
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
        color: Colors.black.withOpacity(0.75),
        child: Text(
          quality.label ?? '',
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
