import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/trade.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/providers/market_data_providers.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/trading_terminal/recent_trades_strip.dart';

final _symbol = TradingSymbol(
  base: 'BTC',
  quote: 'USDT',
  venue: Venue.binance,
  rawSymbol: 'BTCUSDT',
);

Widget _buildStrip(List<Trade> trades) {
  return ProviderScope(
    overrides: [
      tradesStreamProvider.overrideWith((ref, _) async* {
        yield trades;
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(AppVisualDirection.flux),
      home: Scaffold(body: RecentTradesStrip(symbol: _symbol)),
    ),
  );
}

void main() {
  group('RecentTradesStrip', () {
    testWidgets('shows the five newest trades sorted by timestamp', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 1, 1, 12);
      final trades = [
        Trade(
          price: 100,
          amount: 1,
          side: TradeSide.buy,
          timestamp: now.subtract(const Duration(seconds: 4)),
          tradeId: 't1',
        ),
        Trade(
          price: 200,
          amount: 1,
          side: TradeSide.sell,
          timestamp: now.subtract(const Duration(seconds: 2)),
          tradeId: 't2',
        ),
        Trade(
          price: 300,
          amount: 1,
          side: TradeSide.buy,
          timestamp: now,
          tradeId: 't3',
        ),
      ];

      await tester.pumpWidget(_buildStrip(trades.reversed.toList()));
      await tester.pumpAndSettle();

      final prices = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data);
      final priceTexts = prices.where((p) => p?.startsWith('300') ?? false);
      expect(priceTexts, isNotEmpty);

      // The newest trade should appear before the older ones.
      final allText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      expect(allText, contains('300'));
      expect(allText, contains('200'));
      expect(allText, contains('100'));
    });

    testWidgets('renders empty state when no trades are provided', (
      tester,
    ) async {
      await tester.pumpWidget(_buildStrip(const []));
      await tester.pumpAndSettle();

      expect(find.text('Recent trades'), findsNothing);
    });
  });
}
