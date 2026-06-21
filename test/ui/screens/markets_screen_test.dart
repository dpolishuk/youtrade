import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/markets_screen.dart';

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
    testWidgets('renders without overflow and shows search bar', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(MarketsScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('markets_search_field')),
        findsOneWidget,
      );
      expect(find.text('Search symbols, venues, assets'), findsOneWidget);
      expect(find.text('Markets'), findsOneWidget);
    });

    testWidgets('shows filter chips', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Crypto'), findsOneWidget);
      expect(find.text('Forex'), findsOneWidget);
      expect(find.text('Equities'), findsOneWidget);
      expect(find.text('Commodities'), findsOneWidget);
    });

    testWidgets('shows header row and market list', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Symbol'), findsOneWidget);
      expect(find.text('Last · 24h'), findsOneWidget);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('EURUSD'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('XAUUSD'),
        80,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('XAUUSD'), findsOneWidget);
    });

    testWidgets('filters market list by search query', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('EURUSD'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('markets_search_field')),
        'btc',
      );
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('EURUSD'), findsNothing);
    });

    testWidgets('filters market list by chip selection', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('EURUSD'), findsOneWidget);

      await tester.tap(find.text('Forex'));
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsNothing);
      expect(find.text('EURUSD'), findsOneWidget);
      expect(find.text('GBPJPY'), findsOneWidget);
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
