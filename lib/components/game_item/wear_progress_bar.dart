import 'package:flutter/material.dart';

class WearProgressBar extends StatelessWidget {
  const WearProgressBar({
    super.key,
    required this.paintWear,
    this.height = 18,
  });

  final double paintWear;
  final double height;

  @override
  Widget build(BuildContext context) {
    final wear = paintWear.clamp(0.0, 0.8);
    final barHeight = (height * 0.45).clamp(4.0, 10.0);
    final arrowSize = (height * 0.9).clamp(10.0, 16.0);
    final arrowOffset = -(height * 0.11);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final indicatorLeft = (wear * width) - 6;
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: _BarSegment(color: const Color(0xFF008000), height: barHeight),
                  ),
                  Expanded(
                    flex: 8,
                    child: _BarSegment(color: const Color(0xFF5CB85C), height: barHeight),
                  ),
                  Expanded(
                    flex: 23,
                    child: _BarSegment(color: const Color(0xFFF0AD4E), height: barHeight),
                  ),
                  Expanded(
                    flex: 7,
                    child: _BarSegment(color: const Color(0xFFD9534F), height: barHeight),
                  ),
                  Expanded(
                    flex: 65,
                    child: _BarSegment(color: const Color(0xFF993A38), height: barHeight),
                  ),
                ],
              ),
              Positioned(
                left: indicatorLeft < 0 ? 0 : indicatorLeft,
                bottom: arrowOffset,
                child: Icon(
                  Icons.arrow_drop_down,
                  size: arrowSize,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarSegment extends StatelessWidget {
  const _BarSegment({
    required this.color,
    required this.height,
  });

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: color,
    );
  }
}
