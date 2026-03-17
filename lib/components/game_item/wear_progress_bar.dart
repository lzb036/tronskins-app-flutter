import 'package:flutter/material.dart';

class WearProgressBar extends StatelessWidget {
  const WearProgressBar({super.key, required this.paintWear, this.height = 18});

  final double paintWear;
  final double height;

  @override
  Widget build(BuildContext context) {
    final wear = paintWear.clamp(0.0, 0.8);
    final barHeight = (height * 0.45).clamp(4.0, 10.0);
    final markerWidth = (height * 0.55).clamp(8.0, 12.0);
    final markerHeight = (height * 0.35).clamp(4.0, 7.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxLeft = width > markerWidth ? width - markerWidth : 0.0;
        final indicatorLeft = ((wear * width) - (markerWidth / 2))
            .clamp(0.0, maxLeft)
            .toDouble();
        final barTop = ((height - barHeight) / 2).clamp(
          markerHeight - 1,
          height - barHeight,
        );
        final markerTop = (barTop - markerHeight + 1).clamp(
          0.0,
          height - markerHeight,
        );
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: barTop,
                child: SizedBox(
                  height: barHeight,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: _BarSegment(
                          color: const Color(0xFF008000),
                          height: barHeight,
                        ),
                      ),
                      Expanded(
                        flex: 8,
                        child: _BarSegment(
                          color: const Color(0xFF5CB85C),
                          height: barHeight,
                        ),
                      ),
                      Expanded(
                        flex: 23,
                        child: _BarSegment(
                          color: const Color(0xFFF0AD4E),
                          height: barHeight,
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: _BarSegment(
                          color: const Color(0xFFD9534F),
                          height: barHeight,
                        ),
                      ),
                      Expanded(
                        flex: 65,
                        child: _BarSegment(
                          color: const Color(0xFF993A38),
                          height: barHeight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: indicatorLeft,
                top: markerTop,
                child: CustomPaint(
                  size: Size(markerWidth, markerHeight),
                  painter: _WearMarkerPainter(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WearMarkerPainter extends CustomPainter {
  const _WearMarkerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WearMarkerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _BarSegment extends StatelessWidget {
  const _BarSegment({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(height: height, color: color);
  }
}
