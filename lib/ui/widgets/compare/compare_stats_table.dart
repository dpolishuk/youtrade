import 'package:flutter/material.dart';

import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'compare_models.dart';

/// Table showing return and volatility for each selected comparison symbol.
class CompareStatsTable extends StatelessWidget {
  const CompareStatsTable({required this.series, super.key});

  final List<CompareSeries> series;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
              style: AppTheme.mono(color: appColors.tertiaryText, fontSize: 8.5)
                  .copyWith(
                    letterSpacing: 0.06 * 8.5,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              'Return',
              textAlign: TextAlign.right,
              style: AppTheme.mono(color: appColors.tertiaryText, fontSize: 8.5)
                  .copyWith(
                    letterSpacing: 0.06 * 8.5,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              'Volatility',
              textAlign: TextAlign.right,
              style: AppTheme.mono(color: appColors.tertiaryText, fontSize: 8.5)
                  .copyWith(
                    letterSpacing: 0.06 * 8.5,
                    fontWeight: FontWeight.w600,
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
              style: AppTheme.mono(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              '${s.totalReturn >= 0 ? '+' : ''}${s.totalReturn.toStringAsFixed(2)}%',
              textAlign: TextAlign.right,
              style: AppTheme.mono(
                color: s.totalReturn >= 0
                    ? appColors.bullish
                    : appColors.bearish,
                fontSize: 12,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              '${s.volatility.toStringAsFixed(2)}%',
              textAlign: TextAlign.right,
              style: AppTheme.mono(
                color: appColors.subtleText,
                fontSize: 12,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
