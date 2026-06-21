import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';
import 'compare_models.dart';

/// Table showing return and volatility for each selected comparison symbol.
class CompareStatsTable extends StatelessWidget {
  const CompareStatsTable({required this.series, super.key});

  final List<CompareSeries> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColorTheme>()!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(context, appColors),
          for (var i = 0; i < series.length; i++)
            _buildRow(
              context,
              series[i],
              appColors,
              isLast: i == series.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorTheme appColors) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: appColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Symbol',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.06 * 8.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Return',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.06 * 8.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Volatility',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.06 * 8.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    CompareSeries s,
    AppColorTheme appColors, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: appColors.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.symbol.symbol,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${s.totalReturn >= 0 ? '+' : ''}${s.totalReturn.toStringAsFixed(2)}%',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium?.copyWith(
                fontFamily: 'Geist Mono',
                color: s.totalReturn >= 0
                    ? appColors.bullish
                    : appColors.bearish,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${s.volatility.toStringAsFixed(2)}%',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium?.copyWith(
                fontFamily: 'Geist Mono',
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
