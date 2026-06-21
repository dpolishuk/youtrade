import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../presentation/theme/theme_extensions.dart';

/// Available time ranges for the equity curve.
enum EquityRange { oneDay, oneWeek, oneMonth, oneYear, all }

/// Widget that displays a mock equity curve with selectable range chips.
class EquityCurve extends StatefulWidget {
  const EquityCurve({super.key});

  @override
  State<EquityCurve> createState() => _EquityCurveState();
}

class _EquityCurveState extends State<EquityCurve> {
  EquityRange _selectedRange = EquityRange.oneDay;

  static const _rangeLabels = <EquityRange, String>{
    EquityRange.oneDay: '1D',
    EquityRange.oneWeek: '1W',
    EquityRange.oneMonth: '1M',
    EquityRange.oneYear: '1Y',
    EquityRange.all: 'ALL',
  };

  List<FlSpot> _generateSpots() {
    final count = switch (_selectedRange) {
      EquityRange.oneDay => 24,
      EquityRange.oneWeek => 28,
      EquityRange.oneMonth => 30,
      EquityRange.oneYear => 52,
      EquityRange.all => 60,
    };
    final base = 124350.0;
    final spots = <FlSpot>[];
    var value = base;
    for (var i = 0; i < count; i++) {
      value = value * (1 + (i % 7 - 3) * 0.002 + (i % 3) * 0.001);
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final accent = appColors?.accent ?? theme.colorScheme.primary;
    final spots = _generateSpots();

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                minX: spots.first.x,
                maxX: spots.last.x,
                minY:
                    spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) *
                    0.998,
                maxY:
                    spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) *
                    1.002,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: accent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: accent.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 9,
            child: Row(
              children: EquityRange.values.map((range) {
                final isSelected = range == _selectedRange;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _RangeChip(
                    label: _rangeLabels[range]!,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedRange = range),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final accent = appColors?.accent ?? theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: isSelected ? accent : theme.dividerColor),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist Mono',
            fontSize: 10,
            color: isSelected ? accent : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
