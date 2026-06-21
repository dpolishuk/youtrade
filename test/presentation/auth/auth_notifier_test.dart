import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/auth_failure.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';
import 'package:youtrade/presentation/auth/auth_guard_provider.dart';
import 'package:youtrade/presentation/auth/auth_state.dart';

class MockLocalAuthService extends Mock implements LocalAuthService {}

void main() {
  late MockLocalAuthService mockService;

  setUp(() {
    mockService = MockLocalAuthService();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [localAuthServiceProvider.overrideWithValue(mockService)],
    );
  }

  group('AuthNotifier', () {
    test('initial state is AuthUnknown', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(authNotifierProvider), isA<AuthUnknown>());
    });

    test(
      'checkBiometricAvailability transitions to authenticated on success',
      () async {
        when(
          () => mockService.canCheckBiometrics(),
        ).thenAnswer((_) async => true);
        when(
          () => mockService.authenticate(),
        ).thenAnswer((_) async => const Success<bool>(true));

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container
            .read(authNotifierProvider.notifier)
            .checkBiometricAvailability();

        expect(states, [isA<AuthAuthenticated>()]);
      },
    );

    test(
      'checkBiometricAvailability falls back to unauthenticated when biometrics unavailable',
      () async {
        when(
          () => mockService.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container
            .read(authNotifierProvider.notifier)
            .checkBiometricAvailability();

        expect(states, [isA<AuthUnauthenticated>()]);
      },
    );

    test('authenticateWithBiometrics emits authenticated on success', () async {
      when(
        () => mockService.authenticate(),
      ).thenAnswer((_) async => const Success<bool>(true));

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithBiometrics();

      expect(states, [isA<AuthAuthenticated>()]);
    });

    test('authenticateWithBiometrics emits error on cancellation', () async {
      when(
        () => mockService.authenticate(),
      ).thenAnswer((_) async => const Err<bool>(AuthCancelledFailure()));

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithBiometrics();

      expect(states, [isA<AuthError>()]);
      final error = states.single as AuthError;
      expect(error.failure, isA<AuthCancelledFailure>());
    });

    test('authenticateWithBiometrics emits error on failure', () async {
      when(
        () => mockService.authenticate(),
      ).thenAnswer((_) async => const Err<bool>(AuthFailedFailure()));

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithBiometrics();

      expect(states, [isA<AuthError>()]);
      final error = states.single as AuthError;
      expect(error.failure, isA<AuthFailedFailure>());
    });

    test('authenticateWithPin emits authenticated for correct PIN', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin('1234');

      expect(states, [isA<AuthAuthenticated>()]);
    });

    test('authenticateWithPin emits error for incorrect PIN', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin('0000');

      expect(states, [isA<AuthError>()]);
      final error = states.single as AuthError;
      expect(error.failure, isA<PinMismatchFailure>());
    });

    test('authenticateWithPin emits error for empty PIN', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin('');

      expect(states, [isA<AuthError>()]);
      final error = states.single as AuthError;
      expect(error.failure, isA<PinMismatchFailure>());
    });

    test('signOut returns state to unauthenticated', () async {
      when(
        () => mockService.authenticate(),
      ).thenAnswer((_) async => const Success<bool>(true));

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithBiometrics();
      container.read(authNotifierProvider.notifier).signOut();

      expect(states, [isA<AuthAuthenticated>(), isA<AuthUnauthenticated>()]);
    });
  });
}
