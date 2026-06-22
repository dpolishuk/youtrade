import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/markets_screen.dart';
import 'package:youtrade/ui/widgets/markets/market_list_tile.dart';

void main() {
  Widget buildApp() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.carbon),
        home: const MarketsScreen(),
      ),
    );
  }

  group('MarketsScreen', () {
    testWidgets('renders market rows and filters the list', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(MarketsScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('markets_search_field')),
        findsOneWidget,
      );
      expect(find.text('Search symbols, venues, assets'), findsOneWidget);
      expect(find.byType(MarketListTile), findsWidgets);

      final initialCount = find.byType(MarketListTile).evaluate().length;
      await tester.tap(find.text('Crypto'));
      await tester.pumpAndSettle();
      final cryptoCount = find.byType(MarketListTile).evaluate().length;
      expect(cryptoCount, lessThan(initialCount));

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('markets_search_field')),
        'AAPL',
      );
      await tester.pumpAndSettle();
      expect(find.byType(MarketListTile), findsOneWidget);
      expect(find.widgetWithText(MarketListTile, 'AAPL'), findsOneWidget);
    });

    testWidgets('shows mockup filter chips', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Crypto'), findsOneWidget);
      expect(find.text('Stocks'), findsOneWidget);
      expect(find.text('Futures'), findsOneWidget);
      expect(find.text('Options'), findsOneWidget);

      expect(find.text('Forex'), findsNothing);
      expect(find.text('Equities'), findsNothing);
      expect(find.text('Commodities'), findsNothing);
    });

    testWidgets('shows header row and mockup market rows', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Symbol'), findsOneWidget);
      expect(find.text('Last · 24h'), findsOneWidget);

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('SOL'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('GC'), findsOneWidget);
      expect(find.text('NVDA'), findsOneWidget);
      expect(find.text('XRP'), findsWidgets);
      expect(find.text('Bitcoin Perp'), findsOneWidget);
      expect(find.text('Gold Futures'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('CL'),
        80,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('CL'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('BTC-28K-C'),
        80,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('TSLA'), findsOneWidget);
      expect(find.text('BTC-28K-C'), findsOneWidget);
      expect(find.text('BTC Call 70k'), findsOneWidget);
    });

    testWidgets('renders deterministic BTC price and 24h change', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('105,154.0'), findsOneWidget);
      expect(find.text('+6.42%'), findsOneWidget);
    });

    testWidgets('filters market list by search query', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('markets_search_field')),
        'btc',
      );
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('BTC-28K-C'), findsOneWidget);
      expect(find.text('AAPL'), findsNothing);
    });

    testWidgets('filters market list by chip selection', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);

      await tester.tap(find.text('Stocks'));
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsNothing);
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('NVDA'), findsOneWidget);
      expect(find.text('TSLA'), findsOneWidget);
    });

    testWidgets('empty state when no markets match unicode or special chars', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('markets_search_field')),
        '🚀',
      );
      await tester.pumpAndSettle();

      expect(find.text('No markets found'), findsOneWidget);
      expect(find.byType(MarketListTile), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('markets_search_field')),
        '; DROP',
      );
      await tester.pumpAndSettle();

      expect(find.text('No markets found'), findsOneWidget);
      expect(find.byType(MarketListTile), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows empty state when no markets match', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('markets_search_field')),
        'zzzzzz',
      );
      await tester.pumpAndSettle();

      expect(find.text('No markets found'), findsOneWidget);
    });
  });
}
