import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../presentation/theme/theme_extensions.dart';

/// Available time ranges for the equity curve.
enum EquityRange { oneHour, oneDay, oneWeek, oneMonth, oneYear }

/// Widget that displays the deterministic equity curve with selectable range chips.
class EquityCurve extends StatefulWidget {
  const EquityCurve({required this.data, super.key});

  /// Deterministic equity curve values from [DeterministicMarketDataStore].
  final List<double> data;

  @override
  State<EquityCurve> createState() => _EquityCurveState();
}

class _EquityCurveState extends State<EquityCurve> {
  EquityRange _selectedRange = EquityRange.oneDay;

  static const _rangeLabels = <EquityRange, String>{
    EquityRange.oneHour: '1H',
    EquityRange.oneDay: '1D',
    EquityRange.oneWeek: '1W',
    EquityRange.oneMonth: '1M',
    EquityRange.oneYear: '1Y',
  };

  List<FlSpot> get _spots {
    final curve = widget.data;
    final count = switch (_selectedRange) {
      EquityRange.oneHour => 12,
      EquityRange.oneDay => 24,
      EquityRange.oneWeek => 28,
      EquityRange.oneMonth => 30,
      EquityRange.oneYear => curve.length,
    }.clamp(2, curve.length);
    final start = curve.length - count;
    return [
      for (var i = start; i < curve.length; i++)
        FlSpot((i - start).toDouble(), curve[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final accent = appColors?.accent ?? theme.colorScheme.primary;
    final spots = _spots;

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
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        if (index == bar.spots.length - 1) {
                          return FlDotCirclePainter(
                            radius: 3.2,
                            color: accent,
                            strokeWidth: 3.8,
                            strokeColor: accent.withValues(alpha: 0.4),
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 0,
                          color: Colors.transparent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.32),
                          accent.withValues(alpha: 0),
                        ],
                      ),
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
              ? accent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.5)
                : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'JetBrains Mono',
            fontSize: 10,
            color: isSelected ? accent : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
