import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class SparklineChart extends StatelessWidget {
  const SparklineChart({required this.data, super.key});

  final List<double> data;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.1;

    final first = data.first;
    final last = data.last;
    final isUp = last >= first;
    final color = isUp ? appColors.bullish : appColors.bearish;

    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            dotData: const FlDotData(show: false),
            isCurved: false,
            color: color,
            barWidth: 1.5,
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}
