import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/auth_failure.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';
import 'package:youtrade/presentation/auth/auth_guard_provider.dart';
import 'package:youtrade/ui/auth/auth_gate_screen.dart';

class MockLocalAuthService extends Mock implements LocalAuthService {}

void main() {
  late MockLocalAuthService mockService;

  setUp(() {
    mockService = MockLocalAuthService();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [localAuthServiceProvider.overrideWithValue(mockService)],
      child: MaterialApp(
        home: AuthGateScreen(
          child: Scaffold(
            appBar: AppBar(title: const Text('Portfolio')),
            body: const Center(child: Text('Welcome to YouTrade')),
          ),
        ),
      ),
    );
  }

  group('AuthGateScreen', () {
    testWidgets('shows loading while state is unknown', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsNothing);
    });

    testWidgets('shows locked gate when unauthenticated', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('YouTrade is locked'), findsOneWidget);
      expect(find.text('Unlock with biometrics'), findsOneWidget);
      expect(find.text('Unlock with PIN'), findsOneWidget);
      expect(find.text('Welcome to YouTrade'), findsNothing);
    });

    testWidgets('shows protected content after biometric success', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => true);
      when(
        () => mockService.authenticate(),
      ).thenAnswer((_) async => const Success<bool>(true));

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Welcome to YouTrade'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsNothing);
    });

    testWidgets('shows protected content after correct PIN entry', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Unlock with PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to YouTrade'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsNothing);
    });

    testWidgets('shows error after incorrect PIN entry', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '0000');
      await tester.tap(find.text('Unlock with PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsOneWidget);
      expect(find.text('Welcome to YouTrade'), findsNothing);
    });

    testWidgets('shows error when biometric authentication fails', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => true);
      when(
        () => mockService.authenticate(),
      ).thenAnswer((_) async => const Err<bool>(AuthFailedFailure()));

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text('Authentication failed. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('YouTrade is locked'), findsOneWidget);
      expect(find.text('Welcome to YouTrade'), findsNothing);
    });
  });
}
