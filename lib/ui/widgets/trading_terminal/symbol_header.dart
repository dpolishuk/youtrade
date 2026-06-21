import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/candle.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/ticker.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'formatting.dart';

class SymbolHeader extends ConsumerWidget {
  const SymbolHeader({
    required this.symbol,
    required this.tickerAsync,
    required this.candlesAsync,
    super.key,
  });

  final TradingSymbol symbol;
  final AsyncValue<Ticker> tickerAsync;
  final AsyncValue<List<Candle>> candlesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColorTheme>()!;

    final ticker = tickerAsync.valueOrNull;
    final candles = candlesAsync.valueOrNull ?? const <Candle>[];

    final price = ticker?.lastPrice ?? 0.0;
    final change = ticker?.change24h ?? 0.0;
    final changePct = ticker?.change24hPercent ?? 0.0;
    final isUp = changePct >= 0;
    final changeColor = isUp ? appColors.bullish : appColors.bearish;

    final high = candles.isEmpty
        ? 0.0
        : candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final low = candles.isEmpty
        ? 0.0
        : candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final volume = ticker?.volume ?? 0.0;
    final funding = _syntheticFunding(changePct);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        symbol.id,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.02,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: appColors.borderSubtle),
                        ),
                        child: Text(
                          'PERP',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: appColors.subtleText,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.08,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${symbol.base} · ${symbol.venue.displayName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: appColors.subtleText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPrice(price, maxDecimals: 2),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.01,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isUp ? '+' : ''}${formatPrice(change, maxDecimals: 2)} · ${formatPercent(changePct * 100)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          _StatStrip(
            high: high,
            low: low,
            volume: volume,
            funding: funding,
            appColors: appColors,
            theme: theme,
          ),
        ],
      ),
    );
  }

  double _syntheticFunding(double changePct) {
    final base = 0.01;
    return changePct >= 0 ? base : -base;
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.high,
    required this.low,
    required this.volume,
    required this.funding,
    required this.appColors,
    required this.theme,
  });

  final double high;
  final double low;
  final double volume;
  final double funding;
  final AppColorTheme appColors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Stat(label: '24h High', value: formatPrice(high, maxDecimals: 2)),
      _Stat(label: '24h Low', value: formatPrice(low, maxDecimals: 2)),
      _Stat(label: 'Vol', value: formatCompact(volume)),
      _Stat(
        label: 'Funding',
        value: formatPercent(funding),
        valueColor: funding >= 0 ? appColors.bullish : appColors.bearish,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: appColors.borderSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                color: theme.colorScheme.surface,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items[i].label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: appColors.subtleText,
                        letterSpacing: 0.08,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].value,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            items[i].valueColor ?? theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;
}
