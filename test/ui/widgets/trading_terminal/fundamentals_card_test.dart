import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/trading_terminal/fundamentals_card.dart';

final _symbol = TradingSymbol(
  base: 'BTC',
  quote: 'USDT',
  venue: Venue.binance,
  rawSymbol: 'BTCUSDT',
);

final _timestamp = DateTime.utc(2026, 1, 1);

final _ticker = Ticker(
  symbol: _symbol,
  lastPrice: 100000,
  bid: 99900,
  ask: 100100,
  change24h: 1000,
  change24hPercent: 0.01,
  volume: 50000,
  timestamp: _timestamp,
);

final _candles = [
  Candle(
    open: 98000,
    high: 99000,
    low: 97000,
    close: 98500,
    volume: 1000,
    timestamp: _timestamp.subtract(const Duration(hours: 1)),
  ),
  Candle(
    open: 102000,
    high: 104000,
    low: 101000,
    close: 103500,
    volume: 1000,
    timestamp: _timestamp,
  ),
];

Widget _buildCard() {
  return MaterialApp(
    theme: AppTheme.dark(AppVisualDirection.flux),
    home: Scaffold(
      body: SingleChildScrollView(
        child: FundamentalsCard(
          symbol: _symbol,
          ticker: _ticker,
          candles: _candles,
        ),
      ),
    ),
  );
}

void main() {
  group('FundamentalsCard', () {
    testWidgets('renders sentiment and volatility tags for BTC', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.text('Sentiment'), findsOneWidget);
      expect(find.text('Greed 72'), findsOneWidget);
      expect(find.text('Volatility'), findsOneWidget);
      expect(find.text('Med'), findsOneWidget);
    });

    testWidgets('renders BTC stats with exact formatted values', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.text('Market cap'), findsOneWidget);
      expect(find.text('\$1.14T'), findsOneWidget);
      expect(find.text('24h volume'), findsOneWidget);
      expect(find.text('\$38.2B'), findsOneWidget);
      expect(find.text('Funding 8h'), findsOneWidget);
      expect(find.text('+0.0102%'), findsOneWidget);
      expect(find.text('Open interest'), findsOneWidget);
      expect(find.text('\$18.4B'), findsOneWidget);
      expect(find.text('Circ. supply'), findsOneWidget);
      expect(find.text('19.8M'), findsOneWidget);
      expect(find.text('Dominance'), findsOneWidget);
      expect(find.text('54.2%'), findsOneWidget);
      expect(find.text('Long/Short'), findsOneWidget);
      expect(find.text('1.34'), findsOneWidget);
      expect(find.text('Liq. 24h'), findsOneWidget);
      expect(find.text('\$142M'), findsOneWidget);
    });

    testWidgets('renders about section for BTC perpetual swap', (tester) async {
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
      expect(
        find.text(
          'Bitcoin perpetual swap. Funding settles every 8h; no expiry. '
          'Index across Binance, Bybit, OKX, Coinbase.',
        ),
        findsOneWidget,
      );
    });
  });
}
