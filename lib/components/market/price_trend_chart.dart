import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tronskins_app/api/model/market/market_models.dart';
import 'package:tronskins_app/common/hooks/currency/CurrencyController.dart';

class PriceTrendChart extends StatelessWidget {
  const PriceTrendChart({
    super.key,
    required this.points,
  });

  final List<MarketPricePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(child: Text('app.common.no_data'.tr));
    }
    final currency = Get.find<CurrencyController>();
    final sorted = List<MarketPricePoint>.from(points)
      ..sort((a, b) => a.time.compareTo(b.time));
    final spots = <FlSpot>[];
    final times = <DateTime>[];
    for (var i = 0; i < sorted.length; i += 1) {
      spots.add(FlSpot(i.toDouble(), sorted[i].price));
      times.add(_toDateTime(sorted[i].time));
    }

    final maxY = sorted.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    final minY = sorted.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final range = (maxY - minY).abs();
    final double padding =
        range == 0 ? (maxY == 0 ? 1.0 : maxY * 0.1) : range * 0.15;
    final double displayMin =
        (minY - padding) < 0 ? 0.0 : (minY - padding);
    final double displayMax = maxY + padding;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelIndices = _buildLabelIndices(times.length);
    final double bottomInterval =
        times.length <= 1 ? 1.0 : (times.length - 1) / 6;
    final axisDateFormat = _resolveAxisDateFormat(times);
    final leftInterval = _calcInterval(displayMin, displayMax);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26272B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2F3136) : const Color(0xFFE6E8EC),
        ),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: spots.isEmpty ? 0 : spots.last.x,
          minY: displayMin,
          maxY: displayMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: leftInterval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? const Color(0xFF2D2F36) : const Color(0xFFEDEFF2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                  reservedSize: 64,
                  interval: leftInterval,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      _formatAxisPrice(value, currency),
                      style: TextStyle(
                        fontSize: 11,
                        color:
                          isDark ? const Color(0xFFB9BDC7) : const Color(0xFF8A8F9B),
                      ),
                  ),
                ),
              ),
            ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: bottomInterval,
                  getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 ||
                      index >= times.length ||
                      !labelIndices.contains(index)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      axisDateFormat.format(times[index]),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFFB9BDC7)
                            : const Color(0xFF8A8F9B),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: spots.length > 2,
              curveSmoothness: 0.2,
              color: primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) =>
                    spots.isNotEmpty && spot.x == spots.last.x,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3.5,
                  color: primary,
                  strokeColor: isDark ? const Color(0xFF1C1D21) : Colors.white,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primary.withOpacity(0.25),
                    primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 8,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              tooltipBgColor:
                  isDark ? const Color(0xFF1F2024) : Colors.white,
              getTooltipItems: (items) => items.map((item) {
                final index = item.spotIndex;
                final date = index >= 0 && index < times.length
                    ? DateFormat('yyyy-MM-dd').format(times[index])
                    : '';
                return LineTooltipItem(
                  '$date\n${currency.format(item.y)}',
                  TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes
                  .map(
                    (_) => TouchedSpotIndicatorData(
                      FlLine(
                        color: primary.withOpacity(0.35),
                        strokeWidth: 1,
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: primary,
                          strokeColor:
                              isDark ? const Color(0xFF1C1D21) : Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                  .toList();
            },
          ),
        ),
      ),
    );
  }

  DateTime _toDateTime(int value) {
    var timestamp = value;
    if (timestamp < 10000000000) {
      timestamp *= 1000;
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  DateFormat _resolveAxisDateFormat(List<DateTime> times) {
    if (times.length < 2) {
      return DateFormat('MM-dd');
    }
    final spanDays = times.last.difference(times.first).inDays.abs();
    if (spanDays >= 180) {
      return DateFormat('yy/MM');
    }
    if (spanDays >= 60) {
      return DateFormat('MM/dd');
    }
    return DateFormat('MM-dd');
  }

  Set<int> _buildLabelIndices(int length) {
    if (length <= 0) {
      return const <int>{};
    }
    if (length <= 7) {
      return List<int>.generate(length, (index) => index).toSet();
    }
    final desired = 7;
    final step = (length - 1) / (desired - 1);
    final indices = <int>{0, length - 1};
    for (var i = 1; i < desired - 1; i += 1) {
      indices.add((i * step).round());
    }
    if (indices.length < desired) {
      for (var i = 1; i < length - 1 && indices.length < desired; i += 1) {
        indices.add(i);
      }
    }
    return indices;
  }

  double _calcInterval(double min, double max) {
    final range = (max - min).abs();
    if (range == 0) {
      return 1;
    }
    final interval = range / 3;
    return interval <= 0 ? 1 : interval;
  }

  String _formatAxisPrice(double value, CurrencyController currency) {
    final formatted = currency.format(value);
    if (formatted.isNotEmpty) {
      return formatted;
    }
    final formatter = NumberFormat('0.##');
    return '${currency.symbol} ${formatter.format(value)}';
  }
}
