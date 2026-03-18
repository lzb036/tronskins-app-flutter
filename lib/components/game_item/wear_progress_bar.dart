import 'package:flutter/material.dart';

class WearProgressBar extends StatelessWidget {
  const WearProgressBar({super.key, required this.paintWear, this.height = 18});

  final double paintWear;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final wear = paintWear.clamp(0.0, 0.8);
    final barHeight = (height * 0.45).clamp(4.0, 10.0).toDouble();
    final markerWidth = (height * 0.46).clamp(7.0, 10.0).toDouble();
    final markerHeight = (height * 0.66).clamp(8.0, 11.0).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxLeft = width > markerWidth ? width - markerWidth : 0.0;
        final indicatorLeft = ((wear * width) - (markerWidth / 2))
            .clamp(0.0, maxLeft)
            .toDouble();
        final barTop = ((height - barHeight) / 2)
            .clamp(0.0, height - barHeight)
            .toDouble();
        final markerTop = (barTop - (markerHeight * 0.42))
            .clamp(0.0, height - markerHeight)
            .toDouble();
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
                    fillColor: colorScheme.surface,
                    strokeColor: colorScheme.onSurface,
                    highlightColor: colorScheme.onSurfaceVariant,
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
  const _WearMarkerPainter({
    required this.fillColor,
    required this.strokeColor,
    required this.highlightColor,
  });

  final Color fillColor;
  final Color strokeColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final tipHeight = (size.height * 0.34)
        .clamp(2.0, size.height * 0.5)
        .toDouble();
    final bodyHeight = size.height - tipHeight;
    final bodyRadius = Radius.circular(
      (size.width * 0.26).clamp(1.8, 3.4).toDouble(),
    );
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, bodyHeight),
      bodyRadius,
    );

    final tipPath = Path()
      ..moveTo(size.width * 0.28, bodyHeight - 0.25)
      ..lineTo(size.width * 0.72, bodyHeight - 0.25)
      ..lineTo(size.width / 2, size.height)
      ..close();
    final bodyPath = Path()..addRRect(bodyRect);
    final markerPath = Path.combine(PathOperation.union, bodyPath, tipPath);

    canvas.drawShadow(
      markerPath,
      Colors.black.withValues(alpha: 0.20),
      size.width * 0.16,
      true,
    );

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withValues(alpha: 0.98),
          fillColor.withValues(alpha: 0.86),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(markerPath, fillPaint);

    final strokeWidth = (size.width * 0.10).clamp(0.8, 1.2).toDouble();
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = strokeColor.withValues(alpha: 0.46);
    canvas.drawPath(markerPath, strokePaint);

    final highlightPaint = Paint()
      ..strokeWidth = (strokeWidth * 0.9).clamp(0.7, 1.0).toDouble()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = highlightColor.withValues(alpha: 0.26);
    canvas.drawLine(
      Offset(size.width * 0.26, bodyHeight * 0.36),
      Offset(size.width * 0.74, bodyHeight * 0.36),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WearMarkerPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.highlightColor != highlightColor;
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
