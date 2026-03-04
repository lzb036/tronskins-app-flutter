import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tronskins_app/components/game_item/game_item_models.dart';

class StickerRow extends StatelessWidget {
  const StickerRow({super.key, required this.stickers, this.size = 18});

  final List<GameItemSticker> stickers;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (stickers.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: stickers
          .map(
            (sticker) => CachedNetworkImage(
              imageUrl: sticker.imageUrl,
              width: size,
              height: size,
              fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (context, _) => SizedBox(width: size, height: size),
              errorWidget: (context, _, __) =>
                  Icon(Icons.image_not_supported_outlined, size: size),
            ),
          )
          .toList(),
    );
  }
}
