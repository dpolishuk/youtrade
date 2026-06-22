import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';
import 'compare_models.dart';

/// Normalized percentage comparison chart for one or more symbols.
class CompareChart extends StatelessWidget {
  const CompareChart({required this.series, super.key});

  final List<CompareSeries> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColorTheme>()!;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 8),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: _maxX,
            minY: _minY,
            maxY: _maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _gridInterval,
              getDrawingHorizontalLine: (value) {
                if (value == 0) {
                  return FlLine(color: appColors.subtleText, strokeWidth: 1);
                }
                return FlLine(color: appColors.line, strokeWidth: 1);
              },
            ),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              for (final s in series)
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < s.normalized.length; i++)
                      FlSpot(i.toDouble(), s.normalized[i]),
                  ],
                  isCurved: false,
                  color: s.symbol.color,
                  barWidth: 1.8,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      final isLast = index == bar.spots.length - 1;
                      if (isLast) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: s.symbol.color,
                          strokeWidth: 0,
                        );
                      }
                      return FlDotCirclePainter(
                        radius: 0,
                        color: Colors.transparent,
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
            ],
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }

  double get _maxX {
    if (series.isEmpty) return 1;
    return (series.first.normalized.length - 1).toDouble();
  }

  double get _minY {
    if (series.isEmpty) return -1;
    var min = double.infinity;
    for (final s in series) {
      for (final value in s.normalized) {
        if (value < min) min = value;
      }
    }
    return (min / 5).floor() * 5 - 5;
  }

  double get _maxY {
    if (series.isEmpty) return 1;
    var max = double.negativeInfinity;
    for (final s in series) {
      for (final value in s.normalized) {
        if (value > max) max = value;
      }
    }
    return (max / 5).ceil() * 5 + 5;
  }

  double get _gridInterval {
    final range = _maxY - _minY;
    if (range <= 0) return 5;
    return (range / 4).ceilToDouble();
  }
}
