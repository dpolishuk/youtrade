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
    testWidgets('shows the three newest trades sorted by timestamp', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 1, 1, 12);
      final trades = [
        Trade(
          price: 100,
          amount: 1,
          side: TradeSide.sell,
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

      // Prevents regression where the widget renders duplicate rows or loses
      // the five-trade limit.
      final rows = find.descendant(
        of: find.byType(RecentTradesStrip),
        matching: find.byType(Row),
      );
      expect(rows, findsNWidgets(3));

      // Prevents regression where the sort order is inverted so the oldest
      // trade appears first.
      final firstRowTexts = tester.widgetList<Text>(
        find.descendant(of: rows.first, matching: find.byType(Text)),
      );
      expect(firstRowTexts.elementAt(1).data, '300.00');

      // Prevents regression where the oldest trade is not shown at the bottom.
      final lastRowTexts = tester.widgetList<Text>(
        find.descendant(of: rows.last, matching: find.byType(Text)),
      );
      expect(lastRowTexts.elementAt(1).data, '100.00');
    });

    testWidgets('limits to five trades and drops older rows', (tester) async {
      final now = DateTime.utc(2026, 1, 1, 12);
      final trades = List.generate(
        6,
        (i) => Trade(
          price: (i + 1) * 100.0,
          amount: 1,
          side: i.isEven ? TradeSide.buy : TradeSide.sell,
          timestamp: now.subtract(Duration(seconds: (6 - i) * 10)),
          tradeId: 't$i',
        ),
      );

      await tester.pumpWidget(_buildStrip(trades.reversed.toList()));
      await tester.pumpAndSettle();

      // Prevents regression where the limit/take(5) is removed and older rows
      // leak into the UI.
      final rows = find.descendant(
        of: find.byType(RecentTradesStrip),
        matching: find.byType(Row),
      );
      expect(rows, findsNWidgets(5));

      final firstRowTexts = tester.widgetList<Text>(
        find.descendant(of: rows.first, matching: find.byType(Text)),
      );
      expect(firstRowTexts.elementAt(1).data, '600.00');

      final lastRowTexts = tester.widgetList<Text>(
        find.descendant(of: rows.last, matching: find.byType(Text)),
      );
      expect(lastRowTexts.elementAt(1).data, '200.00');

      expect(find.text('100.00'), findsNothing);
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
