import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/providers/market_screener_provider.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'sparkline_chart.dart';

class MarketListTile extends StatelessWidget {
  const MarketListTile({required this.market, this.activeSort, super.key});

  final MarketScreenerItem market;

  /// When non-null, the right column displays the metric corresponding to this
  /// sort option instead of the default price + change view.
  final SortOption? activeSort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
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
                  SizedBox(
                    height: 16,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        market.symbol,
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.01 * 13,
                        ),
                      ),
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
            const SizedBox(width: 11),
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
              const SizedBox(width: 11),
              SizedBox(
                width: 46,
                height: 24,
                child: SparklineChart(data: market.sparkline),
              ),
            ],
            const SizedBox(width: 11),
            SizedBox(
              width: 78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: _rightColumnChildren(context, appColors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the right-column content. The default (and for score / price /
  /// changePct sorts) shows the last price and 24h change. Other sort options
  /// surface the sorted metric value with a tiny label.
  List<Widget> _rightColumnChildren(
    BuildContext context,
    AppColorTheme appColors,
  ) {
    final theme = Theme.of(context);
    switch (activeSort) {
      case SortOption.turnover:
        return _metricColumn(
          _formatCompactMoney(market.turnover24h),
          'VOLUME',
          theme,
          appColors,
        );
      case SortOption.openInterest:
        return _metricColumn(
          _formatCompactMoney(market.openInterestValue),
          'OI',
          theme,
          appColors,
        );
      case SortOption.fundingRate:
        return _metricColumn(
          _formatPercent(market.fundingRate * 100),
          'FUNDING',
          theme,
          appColors,
          valueColor: market.fundingRate >= 0
              ? appColors.bullish
              : appColors.bearish,
        );
      case SortOption.volatility:
        final prev = market.prevPrice24h > 0 ? market.prevPrice24h : 1.0;
        final rangePct =
            (market.highPrice24h - market.lowPrice24h) / prev * 100;
        return _metricColumn(
          _formatPercent(rangePct),
          'VOLAT',
          theme,
          appColors,
        );
      case SortOption.spread:
        final mid = (market.ask1Price + market.bid1Price) / 2;
        final denom = mid > 0 ? mid : 1.0;
        final spreadBps = (market.ask1Price - market.bid1Price) / denom * 10000;
        return _metricColumn(
          '${spreadBps.toStringAsFixed(1)}bp',
          'SPRD',
          theme,
          appColors,
        );
      case null:
      case SortOption.score:
      case SortOption.price:
      case SortOption.changePct:
        final changeColor = market.change24hPercent >= 0
            ? appColors.bullish
            : appColors.bearish;
        final changeSign = market.change24hPercent >= 0 ? '+' : '';
        return [
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
        ];
    }
  }

  /// Renders a metric value (12.5px mono) above a tiny uppercase label
  /// (8.5px mono, muted), matching the height of the default price/change view.
  List<Widget> _metricColumn(
    String value,
    String label,
    ThemeData theme,
    AppColorTheme appColors, {
    Color? valueColor,
  }) {
    return [
      Text(
        value,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: valueColor ?? theme.colorScheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06 * 8.5,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.34),
        ),
      ),
    ];
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

  String _formatCompactMoney(double value) {
    if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '\$${(value / 1e3).toStringAsFixed(1)}K';
    return '\$${value.toStringAsFixed(0)}';
  }

  void _onTap(BuildContext context) {
    context.go('/trading?symbol=${market.rawSymbol}');
  }
}
