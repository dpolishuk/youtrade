import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_extensions.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/trading_terminal/symbol_header.dart';

final _symbol = TradingSymbol(
  base: 'BTC',
  quote: 'USDT',
  venue: Venue.binance,
  rawSymbol: 'BTCUSDT',
);

final _ticker = Ticker(
  symbol: _symbol,
  lastPrice: 105154,
  bid: 105100,
  ask: 105200,
  change24h: 6350,
  change24hPercent: 0.0642,
  volume: 38000,
  timestamp: DateTime.utc(2026, 1, 1),
);

final _candles = <Candle>[
  Candle(
    open: 104000,
    high: 106000,
    low: 103500,
    close: 105154,
    volume: 1000,
    timestamp: DateTime.utc(2026, 1, 1, 0),
  ),
];

void main() {
  group('SymbolHeader', () {
    final theme = AppTheme.dark(AppVisualDirection.flux);
    final appColors = theme.extension<AppColorTheme>()!;

    Widget buildHeader() {
      return ProviderScope(
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SymbolHeader(
              symbol: _symbol,
              tickerAsync: AsyncValue.data(_ticker),
              candlesAsync: AsyncValue.data(_candles),
            ),
          ),
        ),
      );
    }

    testWidgets('symbol text uses exact foreground color', (tester) async {
      await tester.pumpWidget(buildHeader());
      await tester.pumpAndSettle();

      final symbolText = tester.widget<Text>(find.text('BTC'));
      expect(symbolText.style?.color, appColors.foreground);
    });
  });
}
