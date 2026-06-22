import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings / More screen', () {
    testWidgets(
      'shows mockup-aligned content and toggles update state',
      (tester) async {
        await pumpAuthenticatedApp(tester);

        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('More'),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.text('Account'), findsOneWidget);
        expect(find.text('CONNECTED EXCHANGES'), findsOneWidget);
        expect(find.text('Binance'), findsOneWidget);
        expect(find.text('Bybit'), findsOneWidget);
        expect(find.text('OKX'), findsOneWidget);
        expect(find.text('Coinbase'), findsOneWidget);
        expect(find.text('APPEARANCE'), findsOneWidget);
        expect(find.text('DARK'), findsOneWidget);
        expect(find.text('FLUX'), findsOneWidget);
        expect(
          find.text('YouTrade · v1.0 · 4 venues linked'),
          findsOneWidget,
        );
        await binding.takeScreenshot('more_tab_initial');

        await tester.tap(find.text('DARK'));
        await tester.pumpAndSettle();
        expect(find.text('LIGHT'), findsOneWidget);
        expect(find.text('DARK'), findsNothing);

        await tester.tap(find.text('FLUX'));
        await tester.pumpAndSettle();
        expect(find.text('CARBON'), findsOneWidget);
        expect(find.text('FLUX'), findsNothing);
        await binding.takeScreenshot('more_tab_toggled');
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
