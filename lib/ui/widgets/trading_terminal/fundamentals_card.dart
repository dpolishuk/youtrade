import 'package:flutter/material.dart';

import '../../../domain/entities/candle.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/ticker.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'formatting.dart';

class FundamentalsCard extends StatelessWidget {
  const FundamentalsCard({
    required this.symbol,
    required this.ticker,
    required this.candles,
    super.key,
  });

  final TradingSymbol symbol;
  final Ticker? ticker;
  final List<Candle> candles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    final price =
        ticker?.lastPrice ?? (candles.isNotEmpty ? candles.first.close : 0.0);
    final marketCap = price * 19500000;
    final volume24h = ticker?.volume ?? 0.0;
    final open = candles.isNotEmpty ? candles.first.open : 0.0;
    final high = candles.isNotEmpty
        ? candles.map((c) => c.high).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final low = candles.isNotEmpty
        ? candles.map((c) => c.low).reduce((a, b) => a < b ? a : b)
        : 0.0;
    final close = candles.isNotEmpty ? candles.first.close : 0.0;

    final tags = [
      _Tag(label: 'Market cap', value: '\$${formatCompact(marketCap)}'),
      _Tag(
        label: '24h volume',
        value: '\$${formatCompact(volume24h * price)}',
        valueColor: appColors.bullish,
      ),
    ];

    final stats = [
      _Stat(label: 'Open', value: formatPrice(open, maxDecimals: 2)),
      _Stat(label: 'High', value: formatPrice(high, maxDecimals: 2)),
      _Stat(label: 'Low', value: formatPrice(low, maxDecimals: 2)),
      _Stat(label: 'Close', value: formatPrice(close, maxDecimals: 2)),
      _Stat(label: 'Volume', value: formatCompact(volume24h)),
      _Stat(label: 'Avg Vol', value: formatCompact(volume24h * 0.95)),
      _Stat(
        label: 'Circ. Supply',
        value: '${formatCompact(19500000)} ${symbol.base}',
      ),
      _Stat(
        label: 'Max Supply',
        value: '${formatCompact(21000000)} ${symbol.base}',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < tags.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 0 ? 6 : 0),
                  child: _TagCard(
                    tag: tags[i],
                    appColors: appColors,
                    theme: theme,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: appColors.borderSubtle,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3.2,
            children: [
              for (var i = 0; i < stats.length; i++)
                Container(
                  margin: EdgeInsets.only(
                    left: i % 2 == 0 ? 0 : 1,
                    top: i < 2 ? 0 : 1,
                  ),
                  color: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stats[i].label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: appColors.subtleText,
                        ),
                      ),
                      Text(
                        stats[i].value,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'About',
          style: theme.textTheme.labelSmall?.copyWith(
            color: appColors.subtleText,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '${symbol.base} is traded across multiple venues on YouTrade. Prices '
          'and volumes are aggregated from connected exchanges in real-time. '
          'Technical signals are computed from recent market data and are for '
          'informational purposes only.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: appColors.subtleText,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _Tag {
  const _Tag({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;
}

class _Stat {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;
}

class _TagCard extends StatelessWidget {
  const _TagCard({
    required this.tag,
    required this.appColors,
    required this.theme,
  });

  final _Tag tag;
  final AppColorTheme appColors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: appColors.subtleText,
              letterSpacing: 0.07,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tag.value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: tag.valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
