import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Connectivity edge cases', () {
    testWidgets('online to offline transition shows demo banner', (
      tester,
    ) async {
      final controller = await pumpAuthenticatedAppWithConnectivityController(
        tester,
        initialOnline: true,
      );

      expect(find.text('Demo / Offline mode'), findsNothing);

      controller.add(false);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Demo / Offline mode'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('connectivity_online_to_offline');

      await controller.close();
    });

    testWidgets('offline to online transition hides demo banner', (
      tester,
    ) async {
      final controller = await pumpAuthenticatedAppWithConnectivityController(
        tester,
        initialOnline: false,
      );

      expect(find.text('Demo / Offline mode'), findsOneWidget);

      controller.add(true);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Demo / Offline mode'), findsNothing);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('connectivity_offline_to_online');

      await controller.close();
    });

    testWidgets('API timeout shows error state without crash', (tester) async {
      await pumpAuthenticatedAppWithScreenerClient(
        tester,
        screenerClient: timeoutScreenerClient(),
      );

      await tester.tap(find.byKey(const Key('bottom-nav-item-1')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Failed to load markets'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('connectivity_timeout_error');
    });

    testWidgets('API rate limit (429) shows error state without crash', (
      tester,
    ) async {
      await pumpAuthenticatedAppWithScreenerClient(
        tester,
        screenerClient: rateLimitScreenerClient(),
      );

      await tester.tap(find.byKey(const Key('bottom-nav-item-1')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Failed to load markets'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('connectivity_rate_limit_error');
    });
  });
}
