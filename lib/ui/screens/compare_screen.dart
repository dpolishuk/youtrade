import 'package:flutter/material.dart';

import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/theme/theme_extensions.dart';
import '../widgets/compare/compare_chart.dart';
import '../widgets/compare/compare_models.dart';
import '../widgets/compare/compare_stats_table.dart';
import '../widgets/compare/symbol_selector.dart';

/// Compare screen rendered from the YouTrade mockups.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  var _selectedSymbols = List<CompareSymbol>.from(compareSymbols.sublist(0, 3));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    final series = generateCompareSeries(_selectedSymbols);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, appColors),
                const SizedBox(height: 14),
                SymbolSelector(
                  selected: _selectedSymbols,
                  onSelectionChanged: (selected) {
                    setState(() => _selectedSymbols = selected);
                  },
                ),
                const SizedBox(height: 14),
                CompareChart(series: series),
                const SizedBox(height: 14),
                _buildLegend(context, appColors, series),
                const SizedBox(height: 14),
                _buildStatsHeader(context, appColors),
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
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'Compare',
          style: AppTheme.display(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
          ).copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.02 * 18),
        ),
        Text(
          '${_selectedSymbols.length}/4 · normalized %',
          style: AppTheme.mono(
            color: appColors.tertiaryText,
            fontSize: 9,
          ).copyWith(letterSpacing: 0.0),
        ),
      ],
    );
  }

  Widget _buildLegend(
    BuildContext context,
    AppColorTheme appColors,
    List<CompareSeries> series,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
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
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, AppColorTheme appColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '30-period stats',
        style: AppTheme.mono(
          color: appColors.tertiaryText,
          fontSize: 9,
        ).copyWith(letterSpacing: 0.1 * 9),
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
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
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
          style: AppTheme.mono(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 11,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 7),
        Text(
          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
          style: AppTheme.mono(
            color: changeColor,
            fontSize: 11,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
