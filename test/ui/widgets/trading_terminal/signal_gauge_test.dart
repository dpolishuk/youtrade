import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/trading_terminal/signal_gauge.dart';

final _symbol = TradingSymbol(
  base: 'BTC',
  quote: 'USDT',
  venue: Venue.binance,
  rawSymbol: 'BTCUSDT',
);

final _timestamp = DateTime.utc(2026, 1, 1);

final _singleCandle = [
  Candle(
    open: 99000,
    high: 100500,
    low: 98500,
    close: 100000,
    volume: 1000,
    timestamp: _timestamp,
  ),
];

List<Candle> _risingCandles() {
  final now = DateTime.utc(2026, 1, 1);
  return List.generate(25, (i) {
    final close = 100000.0 + i * 120.0;
    return Candle(
      open: close - 50,
      high: close + 100,
      low: close - 100,
      close: close,
      volume: 1000,
      timestamp: now.add(Duration(hours: i - 24)),
    );
  });
}

Ticker _ticker(double lastPrice, double change24hPercent) => Ticker(
  symbol: _symbol,
  lastPrice: lastPrice,
  bid: lastPrice - 100,
  ask: lastPrice + 100,
  change24h: lastPrice * change24hPercent,
  change24hPercent: change24hPercent,
  volume: 50000,
  timestamp: _timestamp,
);

Widget _buildGauge({
  required double change24hPercent,
  double lastPrice = 100000,
  List<Candle>? candles,
}) {
  return MaterialApp(
    theme: AppTheme.dark(AppVisualDirection.flux),
    home: Scaffold(
      body: SingleChildScrollView(
        child: SignalGauge(
          symbol: _symbol,
          ticker: _ticker(lastPrice, change24hPercent),
          candles: candles ?? _singleCandle,
        ),
      ),
    ),
  );
}

void main() {
  group('SignalGauge', () {
    testWidgets('shows BUY for strongly rising 24-candle window', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildGauge(
          lastPrice: 102880,
          change24hPercent: 0.02,
          candles: _risingCandles(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BUY'), findsOneWidget);
      expect(find.text('Oscillator score 68/100'), findsOneWidget);
    });

    testWidgets('shows NEUTRAL for flat single-candle input', (tester) async {
      await tester.pumpWidget(
        _buildGauge(lastPrice: 100000, change24hPercent: 0.0),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEUTRAL'), findsOneWidget);
      expect(find.text('6 buy · 2 sell signals'), findsOneWidget);
      expect(find.text('Oscillator score 51/100'), findsOneWidget);
    });

    testWidgets('shows SELL for strongly falling 24-candle window', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 1, 1);
      final falling = List.generate(25, (i) {
        final close = 100000.0 - i * 120.0;
        return Candle(
          open: close + 50,
          high: close + 100,
          low: close - 100,
          close: close,
          volume: 1000,
          timestamp: now.add(Duration(hours: i - 24)),
        );
      });
      await tester.pumpWidget(
        _buildGauge(
          lastPrice: 97120,
          change24hPercent: -0.02,
          candles: falling,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SELL'), findsOneWidget);
      expect(find.text('Oscillator score 35/100'), findsOneWidget);
    });

    testWidgets('renders oscillators and moving averages sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildGauge(lastPrice: 100000, change24hPercent: 0.0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Oscillators'), findsOneWidget);
      expect(find.text('Moving averages'), findsOneWidget);
      expect(find.text('Pivot levels'), findsOneWidget);
      expect(find.text('RSI (14)'), findsOneWidget);
      expect(find.text('MACD (12,26)'), findsOneWidget);
      expect(find.text('Stoch %K'), findsOneWidget);
      expect(find.text('CCI (20)'), findsOneWidget);
      expect(find.text('Williams %R'), findsOneWidget);
      expect(find.text('MA 7'), findsOneWidget);
      expect(find.text('MA 25'), findsOneWidget);
      expect(find.text('MA 50'), findsOneWidget);
      expect(find.text('MA 99'), findsOneWidget);
      expect(find.text('MA 200'), findsOneWidget);
    });
  });
}
