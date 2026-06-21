import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth cancellation flow', () {
    testWidgets('remains on auth gate and shows error after wrong PIN', (
      tester,
    ) async {
      await pumpLockedApp(tester);

      expect(find.text('YouTrade is locked'), findsOneWidget);

      await enterPin(tester, '0000');

      expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsOneWidget);
      await binding.takeScreenshot('auth_wrong_pin');
    });

    testWidgets('falls back to PIN when biometric auth is cancelled', (
      tester,
    ) async {
      await pumpAppWithBiometricCancellation(tester);

      expect(find.text('YouTrade is locked'), findsOneWidget);
      expect(find.text('Unlock with biometrics'), findsOneWidget);

      await tester.tap(find.text('Unlock with biometrics'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Authentication was cancelled.'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsOneWidget);
      await binding.takeScreenshot('auth_biometric_cancelled');

      await enterPin(tester, '1234');

      expect(find.text('Aggregated net worth · 3 venues'), findsOneWidget);
      await binding.takeScreenshot('auth_biometric_cancelled_fallback');
    });
  });
}
