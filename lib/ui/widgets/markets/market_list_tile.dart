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
    final badgeColor = _badgeColor(context, appColors);

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
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.01 * 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    market.assetClass.badge,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.06 * 7.5,
                      color: badgeColor,
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
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11.5,
                      color: appColors.subtleText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    market.venue.shortCode,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 8.5,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.34,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (market.sparkline.isNotEmpty) ...[
              SizedBox(
                width: 46,
                height: 24,
                child: SparklineChart(data: market.sparkline),
              ),
              const SizedBox(width: 11),
            ],
            SizedBox(
              width: 78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatPrice(market.price, market.priceDecimals),
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$changeSign${_formatPercent(market.change24hPercent)}%',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
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

  Color _badgeColor(BuildContext context, AppColorTheme appColors) {
    switch (market.assetClass) {
      case AssetClass.perp:
        return appColors.accent;
      case AssetClass.spot:
        return appColors.bullish;
    }
  }

  String _formatPrice(double price, int decimals) {
    final s = price.toStringAsFixed(decimals);
    final parts = s.split('.');
    final whole = parts[0];
    final fractional = parts.length > 1 ? '.${parts[1]}' : '';
    final reversed = whole.split('').reversed.join();
    final withCommas = <String>[];
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        withCommas.add(',');
      }
      withCommas.add(reversed[i]);
    }
    return withCommas.reversed.join() + fractional;
  }

  String _formatPercent(double value) {
    return value.toStringAsFixed(2);
  }

  void _onTap(BuildContext context) {
    context.go('/trading?symbol=${market.rawSymbol}');
  }
}
