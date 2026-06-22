import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/candle.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/symbol_metadata.dart';
import '../../../domain/entities/ticker.dart';
import '../../../presentation/theme/app_theme.dart';
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
    final appColors = theme.extension<AppColorTheme>()!;

    final ticker = tickerAsync.valueOrNull;
    final candles = candlesAsync.valueOrNull ?? const <Candle>[];
    final meta = resolveSymbolMetadata(symbol);

    final price = ticker?.lastPrice ?? 0.0;
    final change = ticker?.change24h ?? 0.0;
    final changePct = ticker?.change24hPercent ?? 0.0;
    final isUp = changePct >= 0;
    final changeColor = isUp ? appColors.bullish : appColors.bearish;

    final last24 = candles.length >= 24
        ? candles.sublist(candles.length - 24)
        : candles;
    final high = last24.isEmpty
        ? 0.0
        : last24.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final low = last24.isEmpty
        ? 0.0
        : last24.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final volume = ticker?.volume ?? 0.0;
    final volFormatted = '${(volume).toStringAsFixed(1)}M';

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
                        meta.base,
                        style: AppTheme.display(color: appColors.foreground)
                            .copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.02 * 19,
                              height: 1.0,
                            ),
                      ),
                      const SizedBox(width: 8),
                      _ClassTag(label: meta.symbolClass.label),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${meta.name} · ${meta.venue.displayName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: appColors.tertiaryText,
                      fontSize: 11,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatFixedPrice(price, meta.decimals),
                    style: AppTheme.mono(color: changeColor, fontSize: 24)
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.01 * 24,
                          height: 1.0,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isUp ? '+' : ''}${formatFixedPrice(change, meta.decimals)} · ${formatPercent(changePct)}',
                    style: AppTheme.mono(
                      color: changeColor,
                      fontSize: 12,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          _StatStrip(
            high: high,
            low: low,
            volume: volFormatted,
            funding: '+0.0102%',
            showFunding: meta.showsFunding,
            appColors: appColors,
            onSurface: theme.colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}

class _ClassTag extends StatelessWidget {
  const _ClassTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: appColors.chip,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: Text(
        label,
        style: AppTheme.mono(
          color: appColors.subtleText,
          fontSize: 8,
        ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.08),
      ),
    );
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.high,
    required this.low,
    required this.volume,
    required this.funding,
    required this.showFunding,
    required this.appColors,
    required this.onSurface,
  });

  final double high;
  final double low;
  final String volume;
  final String funding;
  final bool showFunding;
  final AppColorTheme appColors;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final items = <_Stat>[
      _Stat(label: '24H HIGH', value: formatPrice(high, maxDecimals: 2)),
      _Stat(label: '24H LOW', value: formatPrice(low, maxDecimals: 2)),
      _Stat(label: 'VOL', value: volume),
      if (showFunding)
        _Stat(label: 'FUNDING', value: funding, valueColor: appColors.bullish),
    ];

    final theme = Theme.of(context);

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
                color: theme.cardColor,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items[i].label,
                      style: AppTheme.mono(
                        color: appColors.tertiaryText,
                        fontSize: 8.5,
                      ).copyWith(letterSpacing: 0.08),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].value,
                      style: AppTheme.mono(
                        color: items[i].valueColor ?? onSurface,
                        fontSize: 12,
                      ).copyWith(fontWeight: FontWeight.w500),
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
