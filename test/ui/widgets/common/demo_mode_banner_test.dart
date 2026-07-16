import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/providers/connectivity_provider.dart';
import 'package:youtrade/ui/widgets/common/demo_mode_banner.dart';

void main() {
  group('DemoModeBanner', () {
    testWidgets('shows demo/offline text when offline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith((ref) => Stream.value(false)),
          ],
          child: const MaterialApp(home: Scaffold(body: DemoModeBanner())),
        ),
      );
      await tester.pump();

      expect(find.byType(DemoModeBanner), findsOneWidget);
      expect(find.text('Demo / Offline mode'), findsOneWidget);
      expect(find.byIcon(Icons.offline_bolt), findsOneWidget);
    });

    testWidgets('hides when online', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith((ref) => Stream.value(true)),
          ],
          child: const MaterialApp(home: Scaffold(body: DemoModeBanner())),
        ),
      );
      await tester.pump();

      expect(find.text('Demo / Offline mode'), findsNothing);
    });

    testWidgets('updates visibility when connectivity changes', (tester) async {
      final controller = StreamController<bool>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith((ref) => controller.stream),
          ],
          child: const MaterialApp(home: Scaffold(body: DemoModeBanner())),
        ),
      );
      await tester.pump();

      expect(find.text('Demo / Offline mode'), findsNothing);

      controller.add(false);
      await tester.pumpAndSettle();

      expect(find.text('Demo / Offline mode'), findsOneWidget);

      controller.add(true);
      await tester.pumpAndSettle();

      expect(find.text('Demo / Offline mode'), findsNothing);
    });
  });
}
