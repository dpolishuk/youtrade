import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth edge cases', () {
    testWidgets('PIN lockout after 5 failed attempts', (tester) async {
      await pumpLockedApp(tester, initialPin: '1234');

      expect(find.text('YouTrade is locked'), findsOneWidget);

      for (var i = 0; i < 5; i++) {
        await enterPin(tester, '0000');
        expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
      }

      // 6th attempt should trigger lockout.
      await enterPin(tester, '0000');
      expect(find.textContaining('Too many failed attempts'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsOneWidget);
      await binding.takeScreenshot('auth_pin_lockout');
    });

    testWidgets('non-digit PIN rejected', (tester) async {
      await pumpLockedApp(tester, initialPin: '1234');

      expect(find.text('YouTrade is locked'), findsOneWidget);

      await enterPin(tester, '12a4');

      expect(find.text('PIN must be exactly 4 digits'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsOneWidget);
      await binding.takeScreenshot('auth_non_digit_pin');
    });

    testWidgets('short PIN rejected', (tester) async {
      await pumpLockedApp(tester, initialPin: '1234');

      expect(find.text('YouTrade is locked'), findsOneWidget);

      await enterPin(tester, '123');

      expect(find.text('PIN must be exactly 4 digits'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsOneWidget);
      await binding.takeScreenshot('auth_short_pin');
    });

    testWidgets('long PIN rejected', (tester) async {
      await pumpLockedApp(tester, initialPin: '1234');

      expect(find.text('YouTrade is locked'), findsOneWidget);

      // Bypass the TextField's maxLength formatter to submit a 5-digit PIN.
      await enterPinBypassingFormatter(tester, '12345');

      expect(find.text('PIN must be exactly 4 digits'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsOneWidget);
      await binding.takeScreenshot('auth_long_pin');
    });

    testWidgets('leading zeros PIN accepted', (tester) async {
      await pumpLockedApp(tester, initialPin: null);

      expect(find.text('Set up PIN'), findsOneWidget);

      await submitPinForm(tester, '0012');

      expect(find.textContaining('AGGREGATED NET WORTH'), findsOneWidget);
      await binding.takeScreenshot('auth_leading_zeros_pin');
    });

    testWidgets('concurrent PIN attempts do not crash', (tester) async {
      await pumpLockedApp(tester, initialPin: '1234');

      expect(find.text('YouTrade is locked'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1234');

      // Rapidly tap the unlock button multiple times. The _isAuthenticating
      // guard in AuthNotifier prevents concurrent authentication.
      final buttonFinder = find.byType(ElevatedButton);
      await tester.tap(buttonFinder);
      if (buttonFinder.evaluate().isNotEmpty) {
        await tester.tap(buttonFinder);
      }
      if (buttonFinder.evaluate().isNotEmpty) {
        await tester.tap(buttonFinder);
      }

      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.textContaining('AGGREGATED NET WORTH'), findsOneWidget);
      await binding.takeScreenshot('auth_concurrent_pin');
    });
  });
}
