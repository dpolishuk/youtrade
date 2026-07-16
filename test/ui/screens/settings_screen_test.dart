import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';

import 'package:youtrade/presentation/auth/auth_guard_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_extensions.dart';
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
    testWidgets('renders Account title with mockup typography', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text('Account'));
      expect(title.style?.fontFamily, 'Space Grotesk');
      expect(title.style?.fontSize, 18);
      expect(title.style?.fontWeight, FontWeight.w600);
      expect(title.style?.letterSpacing, closeTo(-0.36, 0.001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows connected exchanges section with mockup venues', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('CONNECTED EXCHANGES'), findsOneWidget);
      expect(find.text('Binance'), findsOneWidget);
      expect(find.text('Bybit'), findsOneWidget);
      expect(find.text('OKX'), findsOneWidget);
      expect(find.text('Coinbase'), findsOneWidget);
      expect(find.text('Kraken'), findsNothing);
      expect(find.text('CONNECTED'), findsNWidgets(4));
    });

    testWidgets('connected exchange status uses mockup typography and color', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final context = tester.element(find.text('CONNECTED').first);
      final appColors = Theme.of(context).extension<AppColorTheme>()!;
      final status = tester.widget<Text>(find.text('CONNECTED').first);

      expect(status.style?.fontFamily, 'JetBrains Mono');
      expect(status.style?.fontSize, 9);
      expect(status.style?.fontWeight, FontWeight.w600);
      expect(status.style?.letterSpacing, closeTo(0.45, 0.001));
      expect(status.style?.color, appColors.bullish);
    });

    testWidgets('shows appearance section with uppercase title and toggles', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Visual direction'), findsOneWidget);
      expect(find.text('DARK'), findsOneWidget);
      expect(find.text('FLUX'), findsOneWidget);
    });

    testWidgets('theme toggle button matches mockup styling', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final context = tester.element(find.text('DARK'));
      final appColors = Theme.of(context).extension<AppColorTheme>()!;
      final label = tester.widget<Text>(find.text('DARK'));

      expect(label.style?.fontFamily, 'JetBrains Mono');
      expect(label.style?.fontSize, 11);
      expect(label.style?.fontWeight, FontWeight.w600);
      expect(label.style?.color, appColors.foreground);
    });

    testWidgets('theme toggle switches between uppercase Dark and Light', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('DARK'), findsOneWidget);
      expect(find.text('LIGHT'), findsNothing);

      await tester.tap(find.text('DARK'));
      await tester.pumpAndSettle();

      expect(find.text('LIGHT'), findsOneWidget);
      expect(find.text('DARK'), findsNothing);
    });

    testWidgets(
      'visual direction toggle switches between uppercase Flux and Carbon',
      (tester) async {
        when(
          () => mockService.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('FLUX'), findsOneWidget);
        expect(find.text('CARBON'), findsNothing);

        await tester.tap(find.text('FLUX'));
        await tester.pumpAndSettle();

        expect(find.text('CARBON'), findsOneWidget);
        expect(find.text('FLUX'), findsNothing);
      },
    );

    testWidgets('visual direction toggle uses accent color', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final context = tester.element(find.text('FLUX'));
      final appColors = Theme.of(context).extension<AppColorTheme>()!;
      final label = tester.widget<Text>(find.text('FLUX'));

      expect(label.style?.color, appColors.accent);
    });

    testWidgets('renders version footer with mockup typography', (
      tester,
    ) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final footer = tester.widget<Text>(
        find.text('YouTrade · v1.0 · 4 venues linked'),
      );
      expect(footer.style?.fontFamily, 'JetBrains Mono');
      expect(footer.style?.fontSize, 9);
      expect(footer.style?.letterSpacing, closeTo(0.54, 0.001));
    });

    testWidgets('does not show Protection security section', (tester) async {
      when(
        () => mockService.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Protection'), findsNothing);
      expect(find.text('Set up PIN'), findsNothing);
      expect(find.text('PIN enabled'), findsNothing);
      expect(find.text('Security'), findsNothing);
      expect(find.text('Biometric / PIN'), findsNothing);
      expect(find.text('Sign out'), findsNothing);
    });
  });
}
