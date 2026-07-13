import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/presentation/providers/market_screener_provider.dart';
import 'package:youtrade/presentation/providers/selected_symbol_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/trading_terminal/formatting.dart';
import 'package:youtrade/ui/widgets/trading_terminal/symbol_search_bar.dart';

MarketScreenerItem _screenerItem({
  required String rawSymbol,
  double price = 100.0,
  double change24hPercent = 1.0,
  AssetClass assetClass = AssetClass.perp,
}) {
  return MarketScreenerItem(
    symbol: displaySymbol(rawSymbol),
    rawSymbol: rawSymbol,
    name: rawSymbol,
    venue: Venue.bybit,
    assetClass: assetClass,
    price: price,
    change24hPercent: change24hPercent,
    priceDecimals: 2,
  );
}

final _testItems = [
  _screenerItem(rawSymbol: 'BTCUSDT', price: 65000.0, change24hPercent: 5.23),
  _screenerItem(rawSymbol: 'ETHUSDT', price: 3200.0, change24hPercent: -2.34),
  _screenerItem(rawSymbol: 'SOLUSDT', price: 150.0, change24hPercent: 3.12),
];

Widget buildBar({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      marketScreenerItemsProvider.overrideWith((ref) async => _testItems),
      ...overrides,
    ],
    child: MaterialApp(
      theme: AppTheme.dark(AppVisualDirection.flux),
      home: const Scaffold(body: SymbolSearchBar()),
    ),
  );
}

void main() {
  group('SymbolSearchBar', () {
    testWidgets('shows search input field', (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('symbol_search_field')), findsOneWidget);
    });

    testWidgets('typing filters screener items by symbol', (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('symbol_search_field')),
        'BTC',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('search_result_BTCUSDT')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('search_result_ETHUSDT')), findsNothing);
      expect(find.byKey(const ValueKey('search_result_SOLUSDT')), findsNothing);
    });

    testWidgets('typing filters case insensitive', (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('symbol_search_field')),
        'btc',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('search_result_BTCUSDT')),
        findsOneWidget,
      );
    });

    testWidgets('dropdown shows price and change for each result', (
      tester,
    ) async {
      await tester.pumpWidget(buildBar());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('symbol_search_field')),
        'BTC',
      );
      await tester.pumpAndSettle();

      expect(find.text(formatFixedPrice(65000.0, 2)), findsOneWidget);
      expect(find.text(formatPercent(5.23)), findsOneWidget);
    });

    testWidgets('tapping result sets selected symbol provider', (tester) async {
      final container = ProviderContainer(
        overrides: [
          marketScreenerItemsProvider.overrideWith((ref) async => _testItems),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark(AppVisualDirection.flux),
            home: const Scaffold(body: SymbolSearchBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(selectedSymbolProvider).rawSymbol, 'BTCUSDT');

      await tester.enterText(
        find.byKey(const ValueKey('symbol_search_field')),
        'ETH',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('search_result_ETHUSDT')));
      await tester.pumpAndSettle();

      expect(container.read(selectedSymbolProvider).rawSymbol, 'ETHUSDT');
    });

    testWidgets('dropdown closes on selection', (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('symbol_search_field')),
        'ETH',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('search_result_ETHUSDT')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('search_result_ETHUSDT')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('search_result_ETHUSDT')), findsNothing);
      expect(find.byKey(const ValueKey('search_result_BTCUSDT')), findsNothing);
    });

    testWidgets('shows loading state when screener data loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketScreenerItemsProvider.overrideWith(
              (ref) => Completer<List<MarketScreenerItem>>().future,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(AppVisualDirection.flux),
            home: const Scaffold(body: SymbolSearchBar()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows currently selected symbol as label', (tester) async {
      await tester.pumpWidget(buildBar());
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsOneWidget);
    });

    testWidgets('empty search shows top results limited to 20', (tester) async {
      final manyItems = List.generate(
        25,
        (i) => _screenerItem(rawSymbol: 'TKN${i}USDT'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketScreenerItemsProvider.overrideWith((ref) async => manyItems),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(AppVisualDirection.flux),
            home: const Scaffold(body: SymbolSearchBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('symbol_search_field')));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey &&
              (w.key as ValueKey).value.toString().startsWith('search_result_'),
        ),
        findsNWidgets(20),
      );
    });
  });
}
