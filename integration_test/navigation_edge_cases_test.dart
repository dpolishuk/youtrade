import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:youtrade/presentation/routing/app_router.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation edge cases', () {
    testWidgets('rapid tab switching does not crash', (tester) async {
      await pumpAuthenticatedApp(tester);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('bottom-nav-item-$i')));
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(tester.takeException(), isNull);
      expect(find.text('YouTrade'), findsOneWidget);
      await binding.takeScreenshot('navigation_rapid_tab_switch');
    });

    testWidgets('invalid deep link falls back gracefully', (tester) async {
      await pumpAuthenticatedApp(tester);

      await tester.tap(find.byKey(const Key('bottom-nav-item-2')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final element = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(element);
      final router = container.read(appRouterProvider);
      router.go('/trading?symbol=../../etc');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byKey(const ValueKey('symbol_search_field')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('navigation_invalid_deep_link');
    });

    testWidgets('back navigation returns to previous screen', (tester) async {
      await pumpAuthenticatedApp(tester);

      expect(find.text('AGGREGATED NET WORTH \u00b7 2 VENUES'), findsOneWidget);

      await tester.ensureVisible(find.text('Orders \u2192'));
      await tester.tap(find.text('Orders \u2192'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Orders'), findsOneWidget);

      final element = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(element);
      final router = container.read(appRouterProvider);
      router.pop();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('AGGREGATED NET WORTH \u00b7 2 VENUES'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('navigation_back');
    });

    testWidgets('theme toggle changes app brightness', (tester) async {
      await pumpAuthenticatedApp(tester);

      final initialBrightness = tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .themeMode;
      expect(initialBrightness, ThemeMode.dark);

      await tester.tap(find.byKey(const Key('bottom-nav-item-4')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('theme-toggle')),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final toggledBrightness = tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .themeMode;
      expect(toggledBrightness, ThemeMode.light);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('navigation_theme_toggle');
    });
  });
}
