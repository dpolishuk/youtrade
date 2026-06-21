import 'package:flutter/material.dart';

import '../../presentation/theme/theme_extensions.dart';
import '../widgets/compare/compare_chart.dart';
import '../widgets/compare/compare_models.dart';
import '../widgets/compare/compare_stats_table.dart';
import '../widgets/compare/stat_card.dart';
import '../widgets/compare/symbol_selector.dart';
import '../widgets/compare/time_range_selector.dart';

/// Compare screen rendered from the YouTrade mockups.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  var _selectedSymbols = List<CompareSymbol>.from(compareSymbols.sublist(0, 2));
  var _timeRange = CompareTimeRange.oneMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    final series = generateCompareSeries(
      _selectedSymbols,
      _timeRange.pointCount,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, appColors),
                const SizedBox(height: 12),
                SymbolSelector(
                  selected: _selectedSymbols,
                  onSelectionChanged: (selected) {
                    setState(() => _selectedSymbols = selected);
                  },
                ),
                const SizedBox(height: 14),
                TimeRangeSelector(
                  selected: _timeRange,
                  onSelected: (range) {
                    setState(() => _timeRange = range);
                  },
                ),
                const SizedBox(height: 14),
                CompareChart(series: series),
                const SizedBox(height: 14),
                _buildLegend(context, series),
                const SizedBox(height: 14),
                if (series.length == 2) _buildStatCards(context, series),
                const SizedBox(height: 8),
                _buildStatsHeader(context),
                const SizedBox(height: 9),
                CompareStatsTable(series: series),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorTheme appColors) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Compare',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.02 * 18,
          ),
        ),
        Text(
          '${_selectedSymbols.length}/4 · normalized %',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, List<CompareSeries> series) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        for (final s in series)
          _LegendItem(
            symbol: s.symbol.symbol,
            color: s.symbol.color,
            change: s.totalReturn,
          ),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context, List<CompareSeries> series) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final corr = correlation(series[0], series[1]);
    final ratio = priceRatio(series[0], series[1]);

    return Row(
      children: [
        StatCard(
          label: 'Correlation',
          value: corr.toStringAsFixed(2),
          valueColor: appColors.accent,
        ),
        const SizedBox(width: 10),
        StatCard(
          label: 'Ratio',
          value: ratio.toStringAsFixed(3),
          valueColor: appColors.accent,
        ),
      ],
    );
  }

  Widget _buildStatsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '${_timeRange.pointCount}-period stats',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.1 * 9,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.symbol,
    required this.color,
    required this.change,
  });

  final String symbol;
  final Color color;
  final double change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final changeColor = change >= 0 ? appColors.bullish : appColors.bearish;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          symbol,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
          style: theme.textTheme.labelMedium?.copyWith(
            fontFamily: 'Geist Mono',
            color: changeColor,
          ),
        ),
      ],
    );
  }
}
