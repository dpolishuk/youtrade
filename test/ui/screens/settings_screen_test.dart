import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';

import 'package:youtrade/presentation/auth/auth_guard_provider.dart';
import 'package:youtrade/presentation/auth/auth_state.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/settings_screen.dart';

import '../../fakes/fake_pin_auth_service.dart';

class MockLocalAuthService extends Mock implements LocalAuthService {}

void main() {
  late MockLocalAuthService mockService;
  late FakePinAuthService fakePinAuth;

  setUp(() {
    mockService = MockLocalAuthService();
    fakePinAuth = FakePinAuthService(initialPin: '1234');
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        localAuthServiceProvider.overrideWithValue(mockService),
        pinAuthServiceProvider.overrideWithValue(fakePinAuth),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.flux),
        home: const SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen', () {
    testWidgets('renders without overflow', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows connected exchanges list', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Connected exchanges'), findsOneWidget);
      expect(find.text('Binance'), findsOneWidget);
      expect(find.text('Bybit'), findsOneWidget);
      expect(find.text('Coinbase'), findsOneWidget);
      expect(find.text('Kraken'), findsOneWidget);
      expect(find.text('Connected'), findsNWidgets(4));
    });

    testWidgets('shows appearance toggles', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Visual direction'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Flux'), findsOneWidget);
    });

    testWidgets('theme toggle switches between light and dark', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsNothing);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsNothing);
    });

    testWidgets('visual direction toggle switches between Flux and Carbon', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Flux'), findsOneWidget);
      expect(find.text('Carbon'), findsNothing);

      await tester.tap(find.text('Flux'));
      await tester.pumpAndSettle();

      expect(find.text('Carbon'), findsOneWidget);
      expect(find.text('Flux'), findsNothing);
    });

    testWidgets('shows sign out option', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Biometric / PIN'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('tapping sign out transitions to unauthenticated', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(authNotifierProvider), const AuthUnknown());

      await tester.tap(find.text('Sign out'));
      await tester.pump();

      // Catches bug where sign out leaves the user authenticated.
      final authState = container.read(authNotifierProvider);
      expect(authState, isA<AuthUnauthenticated>());
      expect((authState as AuthUnauthenticated).pinSet, false);
    });

    testWidgets('tapping Biometric/PIN navigates to auth gate', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Biometric / PIN'));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
    });
  });
}
