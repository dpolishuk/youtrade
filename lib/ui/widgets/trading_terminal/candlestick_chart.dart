import 'package:candlesticks/candlesticks.dart' as candlesticks;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/candle.dart';
import '../../../domain/entities/symbol.dart';
import '../../../presentation/providers/market_data_providers.dart';
import '../../../presentation/theme/theme_extensions.dart';

class CandlestickChart extends ConsumerWidget {
  const CandlestickChart({required this.symbol, super.key});

  final TradingSymbol symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candlesAsync = ref.watch(candlesProvider(symbol));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColorTheme>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 248,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: appColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: candlesAsync.when(
          data: (candles) => _ChartBody(
            candles: candles,
            appColors: appColors,
            colorScheme: colorScheme,
          ),
          loading: () => Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Chart unavailable',
              style: theme.textTheme.bodySmall?.copyWith(
                color: appColors.subtleText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartBody extends StatelessWidget {
  const _ChartBody({
    required this.candles,
    required this.appColors,
    required this.colorScheme,
  });

  final List<Candle> candles;
  final AppColorTheme appColors;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final chartCandles = candles
        .map(
          (c) => candlesticks.Candle(
            date: c.timestamp,
            open: c.open,
            high: c.high,
            low: c.low,
            close: c.close,
            volume: c.volume,
          ),
        )
        .toList();

    final ma7 = _movingAverage(candles, 7);
    final ma25 = _movingAverage(candles, 25);

    return Stack(
      children: [
        candlesticks.Candlesticks(candles: chartCandles, style: _buildStyle()),
        Positioned(
          top: 7,
          left: 10,
          child: Row(
            children: [
              _MaLabel(label: 'MA7', value: ma7, color: Colors.orange),
              const SizedBox(width: 9),
              _MaLabel(label: 'MA25', value: ma25, color: Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  candlesticks.CandleSticksStyle _buildStyle() {
    final isLight = colorScheme.brightness == Brightness.light;
    final styleBuilder = isLight
        ? candlesticks.CandleSticksStyle.light
        : candlesticks.CandleSticksStyle.dark;

    return styleBuilder(
      chartBackgroundColor: colorScheme.surface,
      candleBullColor: appColors.bullish,
      candleBearColor: appColors.bearish,
      volumeBullColor: appColors.bullish.withOpacity(0.5),
      volumeBearColor: appColors.bearish.withOpacity(0.5),
      gridLineColor: appColors.borderSubtle,
      axisTextColor: appColors.subtleText,
      crosshairLineColor: appColors.subtleText,
      crosshairLabelBackgroundColor: appColors.surfaceGlass,
      crosshairLabelTextColor: colorScheme.onSurface,
      ohlcInfoTextColor: appColors.subtleText,
      ohlcInfoBullColor: appColors.bullish,
      ohlcInfoBearColor: appColors.bearish,
      priceIndicatorTextColor: colorScheme.onSurface,
      loadingIndicatorColor: colorScheme.primary,
    );
  }

  double _movingAverage(List<Candle> data, int period) {
    if (data.length < period) return 0;
    final slice = data.take(period);
    final sum = slice.fold(0.0, (acc, c) => acc + c.close);
    return sum / period;
  }
}

class _MaLabel extends StatelessWidget {
  const _MaLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      text: TextSpan(
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(color: color),
          ),
          TextSpan(
            text: value > 0 ? value.toStringAsFixed(2) : '-',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
