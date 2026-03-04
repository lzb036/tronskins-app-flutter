import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';

class GemRow extends StatelessWidget {
  const GemRow({super.key, required this.gems, this.size = 18});

  final List<GameItemGem> gems;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (gems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: gems
          .map(
            (gem) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                border: gem.borderColor != null
                    ? Border.all(color: gem.borderColor!, width: 1.4)
                    : null,
              ),
              child: CachedNetworkImage(
                imageUrl: gem.imageUrl,
                fit: BoxFit.contain,
                fadeInDuration: const Duration(milliseconds: 120),
                placeholder: (context, _) =>
                    SizedBox(width: size, height: size),
                errorWidget: (context, _, __) =>
                    Icon(Icons.image_not_supported_outlined, size: size),
              ),
            ),
          )
          .toList(),
    );
  }
}
