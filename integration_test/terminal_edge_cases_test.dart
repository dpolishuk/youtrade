import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:youtrade/presentation/routing/app_router.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> navigateToTerminal(WidgetTester tester) async {
    await pumpAuthenticatedApp(tester);
    await tester.tap(find.byKey(const Key('bottom-nav-item-2')));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  group('Trading Terminal edge cases', () {
    testWidgets('symbol search filters results', (tester) async {
      await navigateToTerminal(tester);

      await tester.tap(find.byKey(const ValueKey('symbol_search_field')));
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
      await binding.takeScreenshot('terminal_search_btc');
    });

    testWidgets('symbol search shows no results for unknown query', (
      tester,
    ) async {
      await navigateToTerminal(tester);

      await tester.tap(find.byKey(const ValueKey('symbol_search_field')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('symbol_search_field')),
        'ZZZZZ',
      );
      await tester.pumpAndSettle();

      expect(find.text('No symbols found'), findsOneWidget);
      await binding.takeScreenshot('terminal_search_no_results');
    });

    testWidgets('symbol search select loads symbol data', (tester) async {
      await navigateToTerminal(tester);

      await tester.tap(find.byKey(const ValueKey('symbol_search_field')));
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
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('ETHUSDT'), findsWidgets);
      await binding.takeScreenshot('terminal_search_select_eth');
    });

    testWidgets('invalid deep link symbol shows graceful fallback', (
      tester,
    ) async {
      await navigateToTerminal(tester);

      final element = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(element);
      final router = container.read(appRouterProvider);
      router.go('/trading?symbol=INVALID!');
      await tester.pumpAndSettle();

      expect(find.textContaining('Invalid symbol parameter'), findsOneWidget);
      expect(find.byKey(const ValueKey('symbol_search_field')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('terminal_invalid_deep_link');
    });

    testWidgets('timeframe switching does not crash', (tester) async {
      await navigateToTerminal(tester);

      expect(find.text('1H'), findsOneWidget);

      await tester.tap(find.text('5M'));
      await tester.pump(const Duration(seconds: 3));

      expect(find.byKey(const ValueKey('symbol_search_field')), findsOneWidget);
      expect(find.text('1H'), findsOneWidget);
      expect(find.text('5M'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('terminal_timeframe_5m');
    });

    testWidgets('order ticket submit shows demo confirmation dialog', (
      tester,
    ) async {
      await navigateToTerminal(tester);

      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Demo Buy'), findsOneWidget);
      expect(
        find.textContaining('No real order will be placed.'),
        findsOneWidget,
      );
      await binding.takeScreenshot('terminal_order_demo_dialog');

      await tester.tap(find.text('OK'));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('order ticket size selection updates order size', (
      tester,
    ) async {
      await navigateToTerminal(tester);

      await tester.ensureVisible(find.text('100%'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1.050'), findsOneWidget);

      await tester.tap(find.text('100%'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('4.200'), findsOneWidget);
      await binding.takeScreenshot('terminal_order_size_100');
    });

    testWidgets('lower tab switching changes content', (tester) async {
      await navigateToTerminal(tester);

      expect(find.text('Buy / Long'), findsOneWidget);

      await tester.tap(find.text('Book'));
      await tester.pump(const Duration(seconds: 3));
      expect(find.textContaining('spread'), findsOneWidget);
      await binding.takeScreenshot('terminal_tab_book');

      await tester.tap(find.text('Info'));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('ABOUT'), findsOneWidget);
      await binding.takeScreenshot('terminal_tab_info');

      await tester.tap(find.text('Signals'));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('OSCILLATORS'), findsOneWidget);
      await binding.takeScreenshot('terminal_tab_signals');
    });
  });
}
