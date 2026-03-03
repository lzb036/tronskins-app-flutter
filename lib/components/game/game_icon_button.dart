import 'package:flutter/material.dart';

class GameIconButton extends StatelessWidget {
  const GameIconButton({
    super.key,
    required this.appId,
    required this.onTap,
    this.size = 40,
  });

  final int appId;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = 10.0;
    final iconSize = size;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'assets/images/game/icon/$appId.png',
            width: iconSize,
            height: iconSize,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.videogame_asset,
                size: size * 0.65,
                color: colors.onSurfaceVariant,
              );
            },
          ),
        ),
      ),
    );
  }
}
