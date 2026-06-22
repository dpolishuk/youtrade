import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/auth_failure.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';

import 'package:youtrade/presentation/auth/auth_guard_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/auth/auth_gate_screen.dart';

import '../../fakes/fake_pin_auth_service.dart';

class MockLocalAuthService extends Mock implements LocalAuthService {}

void main() {
  late MockLocalAuthService mockService;
  late FakePinAuthService fakePinAuth;

  setUp(() {
    mockService = MockLocalAuthService();
    fakePinAuth = FakePinAuthService();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        localAuthServiceProvider.overrideWithValue(mockService),
        pinAuthServiceProvider.overrideWithValue(fakePinAuth),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.carbon),
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
      await tester.pumpWidget(buildApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsNothing);
    });

    testWidgets('shows set PIN flow when no PIN is configured', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Set up PIN'), findsOneWidget);
      expect(
        find.text('Create a 4-digit PIN to secure YouTrade'),
        findsOneWidget,
      );
      expect(find.text('Set PIN'), findsOneWidget);
      expect(find.text('Unlock with biometrics'), findsNothing);
      expect(find.text('Welcome to YouTrade'), findsNothing);
    });

    testWidgets('shows locked gate when PIN is set', (tester) async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('YouTrade is locked'), findsOneWidget);
      expect(find.text('Unlock with PIN'), findsOneWidget);
      expect(find.text('Welcome to YouTrade'), findsNothing);
    });

    testWidgets('shows protected content after biometric success', (
      tester,
    ) async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => true);
      when(
        () => mockService.authenticate(),
      ).thenAnswer((_) async => const Success<bool>(true));

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Unlock with biometrics'), findsOneWidget);
      await tester.tap(find.text('Unlock with biometrics'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to YouTrade'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsNothing);
    });

    testWidgets('sets PIN and shows protected content on first use', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '5678');
      await tester.tap(find.text('Set PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to YouTrade'), findsOneWidget);
      expect(find.text('Set up PIN'), findsNothing);
    });

    testWidgets('shows protected content after correct PIN entry', (
      tester,
    ) async {
      fakePinAuth.setStoredPin('1234');
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
      fakePinAuth.setStoredPin('1234');
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

    testWidgets('shows validation error on empty PIN submission', (
      tester,
    ) async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unlock with PIN'));
      await tester.pumpAndSettle();

      expect(find.text('PIN must be exactly 4 digits'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsOneWidget);
      expect(find.text('Welcome to YouTrade'), findsNothing);
    });

    testWidgets('truncates very long PIN to max length and unlocks', (
      tester,
    ) async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1234567890');
      await tester.tap(find.text('Unlock with PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to YouTrade'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsNothing);
    });

    testWidgets('handles rapid biometric and PIN taps without crashing', (
      tester,
    ) async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Unlock with PIN'));
      await tester.tap(find.text('Unlock with PIN'));
      await tester.tap(find.text('Unlock with PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to YouTrade'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsNothing);
    });

    testWidgets('treats whitespace-only pasted input as invalid', (
      tester,
    ) async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Unlock with PIN'));
      await tester.pumpAndSettle();

      expect(find.text('PIN must be exactly 4 digits'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsOneWidget);
      expect(find.text('Welcome to YouTrade'), findsNothing);
    });

    testWidgets('treats multi-line pasted input as invalid', (tester) async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '12\n3');
      await tester.tap(find.text('Unlock with PIN'));
      await tester.pumpAndSettle();

      expect(find.text('PIN must be exactly 4 digits'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsOneWidget);
      expect(find.text('Welcome to YouTrade'), findsNothing);
    });

    testWidgets('allows PIN entry after biometric failure', (tester) async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => true);
      when(
        () => mockService.authenticate(),
      ).thenAnswer((_) async => const Err<bool>(AuthFailedFailure()));

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Unlock with biometrics'), findsOneWidget);
      await tester.tap(find.text('Unlock with biometrics'));
      await tester.pumpAndSettle();

      expect(
        find.text('Authentication failed. Please try again.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Unlock with PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to YouTrade'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsNothing);
    });

    testWidgets('shows error when biometric authentication fails', (
      tester,
    ) async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => true);
      when(
        () => mockService.authenticate(),
      ).thenAnswer((_) async => const Err<bool>(AuthFailedFailure()));

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Unlock with biometrics'), findsOneWidget);
      await tester.tap(find.text('Unlock with biometrics'));
      await tester.pumpAndSettle();

      expect(
        find.text('Authentication failed. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('YouTrade is locked'), findsOneWidget);
      expect(find.text('Welcome to YouTrade'), findsNothing);
    });

    testWidgets(
      'entering correct PIN then wrong PIN shows error and keeps locked',
      (tester) async {
        fakePinAuth.setStoredPin('1234');
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

        final container = ProviderScope.containerOf(
          tester.element(find.text('Welcome to YouTrade')),
        );
        container.read(authNotifierProvider.notifier).signOut();
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '0000');
        await tester.tap(find.text('Unlock with PIN'));
        await tester.pumpAndSettle();

        expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
        expect(find.text('YouTrade is locked'), findsOneWidget);
        expect(find.text('Welcome to YouTrade'), findsNothing);
      },
    );

    testWidgets('pasting non-digit PIN after truncation is rejected', (
      tester,
    ) async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'abcdefgh');
      await tester.tap(find.text('Unlock with PIN'));
      await tester.pumpAndSettle();

      expect(find.text('PIN must be exactly 4 digits'), findsOneWidget);
      expect(find.text('YouTrade is locked'), findsOneWidget);
      expect(find.text('Welcome to YouTrade'), findsNothing);
    });

    testWidgets('title uses mockup font size 28', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text('Set up PIN'));
      expect(title.style?.fontSize, 28);
    });

    testWidgets('primary CTA text uses dark foreground color', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final foreground = button.style?.foregroundColor?.resolve({});
      expect(foreground, const Color(0xFF06080F));

      final label = tester.widget<Text>(find.text('Set PIN'));
      expect(label.style?.color, const Color(0xFF06080F));
    });

    testWidgets('gate content renders inside branded card', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pumpAndSettle();

      final card = tester.widget<Container>(
        find.byKey(const Key('authGateCard')),
      );
      final decoration = card.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFF0E131F));
      expect(decoration.borderRadius, BorderRadius.circular(16));
      expect(
        (decoration.border as Border?)?.top.color,
        const Color(0x12FFFFFF),
      );
    });
  });
}
