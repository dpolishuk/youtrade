import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/ticker.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/trading_terminal/trade_ticket.dart';

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

void main() {
  group('TradeTicket', () {
    Widget buildTicket() {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(AppVisualDirection.flux),
          home: Scaffold(
            body: TradeTicket(
              symbol: _symbol,
              tickerAsync: AsyncValue.data(_ticker),
            ),
          ),
        ),
      );
    }

    testWidgets('renders uppercase trade ticket labels', (tester) async {
      await tester.pumpWidget(buildTicket());
      await tester.pumpAndSettle();

      expect(find.text('PRICE'), findsOneWidget);
      expect(find.text('LEVERAGE'), findsOneWidget);
      expect(find.text('ORDER SIZE'), findsOneWidget);
    });
  });
}
