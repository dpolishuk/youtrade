import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/providers/market_screener_provider.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'sparkline_chart.dart';

class MarketListTile extends StatelessWidget {
  const MarketListTile({required this.market, super.key});

  final MarketScreenerItem market;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final changeColor = market.change24hPercent >= 0
        ? appColors.bullish
        : appColors.bearish;
    final changeSign = market.change24hPercent >= 0 ? '+' : '';

    return InkWell(
      onTap: () => _onTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: appColors.borderSubtle)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    market.symbol,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.01 * 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    market.assetClass.label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.06 * 7.5,
                      color: appColors.subtleText,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    market.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    market.venue.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 8.5,
                      color: appColors.subtleText,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 46,
              height: 24,
              child: SparklineChart(data: market.sparkline),
            ),
            const SizedBox(width: 11),
            SizedBox(
              width: 78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatPrice(market.price),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'Geist',
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$changeSign${_formatPercent(market.change24hPercent)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 10000) {
      return price.toStringAsFixed(2);
    } else if (price >= 100) {
      return price.toStringAsFixed(2);
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    }
    return price.toStringAsFixed(4);
  }

  String _formatPercent(double value) {
    return value.toStringAsFixed(2);
  }

  void _onTap(BuildContext context) {
    if (market.assetClass == AssetClass.options) {
      context.go('/markets/options/${market.symbol}');
    } else {
      context.go('/trading?symbol=${market.symbol}');
    }
  }
}
