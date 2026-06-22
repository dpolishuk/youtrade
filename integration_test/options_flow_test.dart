import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Options chain flow', () {
    testWidgets(
      'shows BTC options chain with deterministic strikes and ATM highlight',
      (tester) async {
        await pumpAuthenticatedAppWithMockStore(tester, online: false);

        await tester.tap(find.byKey(const Key('bottom-nav-item-3')));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.text('BTC'), findsWidgets);
        expect(find.text('OPTIONS'), findsOneWidget);
        expect(find.text('105,154'), findsOneWidget);
        expect(find.text('SPOT'), findsOneWidget);

        expect(find.text('26 JUN'), findsOneWidget);
        expect(find.text('25 JUL'), findsOneWidget);
        expect(find.text('29 AUG'), findsOneWidget);
        expect(find.text('26 SEP'), findsOneWidget);

        expect(find.text('CALLS'), findsOneWidget);
        expect(find.text('STRIKE'), findsOneWidget);
        expect(find.text('PUTS'), findsOneWidget);

        expect(find.text('ATM strike 106,000 · highlighted'), findsOneWidget);

        for (final strike in [
          '98,000',
          '100,000',
          '102,000',
          '104,000',
          '106,000',
          '108,000',
          '110,000',
          '112,000',
          '114,000',
        ]) {
          expect(find.text(strike), findsOneWidget);
        }

        await binding.takeScreenshot('options_chain_tab');

        await tester.tap(find.text('25 JUL'));
        await tester.pumpAndSettle();

        expect(find.text('25 JUL'), findsOneWidget);
        expect(find.text('ATM strike 106,000 · highlighted'), findsOneWidget);
        await binding.takeScreenshot('options_chain_expiry_switched');
      },
    );
  });
}
