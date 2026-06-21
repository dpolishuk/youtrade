import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/auth_failure.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/presentation/auth/auth_guard_provider.dart';
import 'package:youtrade/presentation/auth/auth_state.dart';

import '../../fakes/fake_pin_auth_service.dart';
import '../../fakes/racey_fake_pin_auth_service.dart';

class MockLocalAuthService extends Mock implements LocalAuthService {}

void main() {
  late MockLocalAuthService mockLocalAuth;
  late FakePinAuthService fakePinAuth;

  setUp(() {
    mockLocalAuth = MockLocalAuthService();
    fakePinAuth = FakePinAuthService();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        localAuthServiceProvider.overrideWithValue(mockLocalAuth),
        pinAuthServiceProvider.overrideWithValue(fakePinAuth),
      ],
    );
  }

  group('AuthNotifier', () {
    test('initial state is AuthUnknown', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(authNotifierProvider), isA<AuthUnknown>());
    });

    test(
      'initialize transitions to set-pin flow when no PIN is configured',
      () async {
        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container.read(authNotifierProvider.notifier).initialize();

        expect(states, [isA<AuthUnauthenticated>()]);
        final unauthenticated = states.single as AuthUnauthenticated;
        expect(unauthenticated.pinSet, isFalse);
        expect(container.read(authNotifierProvider.notifier).isPinSet, isFalse);
      },
    );

    test(
      'initialize transitions to authenticated when biometrics are available',
      () async {
        fakePinAuth.setStoredPin('1234');
        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenAnswer((_) async => true);
        when(
          () => mockLocalAuth.authenticate(),
        ).thenAnswer((_) async => const Success<bool>(true));

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container.read(authNotifierProvider.notifier).initialize();

        expect(states, [isA<AuthAuthenticated>()]);
      },
    );

    test(
      'initialize falls back to PIN entry when biometrics are unavailable',
      () async {
        fakePinAuth.setStoredPin('1234');
        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container.read(authNotifierProvider.notifier).initialize();

        expect(states, [isA<AuthUnauthenticated>()]);
        final unauthenticated = states.single as AuthUnauthenticated;
        expect(unauthenticated.pinSet, isTrue);
      },
    );

    test('authenticateWithBiometrics emits authenticated on success', () async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockLocalAuth.authenticate(),
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
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockLocalAuth.authenticate(),
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
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockLocalAuth.authenticate(),
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

    test(
      'authenticateWithPin sets PIN and authenticates on first use',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('5678');

        expect(states, [isA<AuthAuthenticated>()]);
        expect(container.read(authNotifierProvider.notifier).isPinSet, isTrue);
        expect(await fakePinAuth.authenticatePin('5678'), isTrue);
      },
    );

    test('authenticateWithPin emits authenticated for correct PIN', () async {
      fakePinAuth.setStoredPin('1234');
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
      fakePinAuth.setStoredPin('1234');
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
      fakePinAuth.setStoredPin('1234');
      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin('');

      expect(states, [isA<AuthError>()]);
      final error = states.single as AuthError;
      expect(error.failure, isA<PinValidationFailure>());
      expect(error.failure.message, 'PIN must be exactly 4 digits');
    });

    test('authenticateWithPin rejects PIN with whitespace', () async {
      fakePinAuth.setStoredPin('1234');
      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin(' 1234');

      expect(states, [isA<AuthError>()]);
      final error = states.single as AuthError;
      expect(error.failure, isA<PinValidationFailure>());
      expect(error.failure.message, 'PIN must be exactly 4 digits');
    });

    test('authenticateWithPin rejects PIN with non-digit characters', () async {
      fakePinAuth.setStoredPin('1234');
      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin('12a4');

      expect(states, [isA<AuthError>()]);
      final error = states.single as AuthError;
      expect(error.failure, isA<PinValidationFailure>());
      expect(error.failure.message, 'PIN must be exactly 4 digits');
    });

    test('authenticateWithPin rejects non-digit PIN on first use', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin('abcd');

      expect(states, [isA<AuthError>()]);
      final error = states.single as AuthError;
      expect(error.failure, isA<PinValidationFailure>());
      expect(error.failure.message, 'PIN must be exactly 4 digits');
      expect(container.read(authNotifierProvider.notifier).isPinSet, isFalse);
    });

    test(
      'initialize treats canCheckBiometrics exception as unavailable',
      () async {
        fakePinAuth.setStoredPin('1234');
        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenThrow(Exception('biometrics service unavailable'));

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container.read(authNotifierProvider.notifier).initialize();

        expect(states, [isA<AuthUnauthenticated>()]);
        final unauthenticated = states.single as AuthUnauthenticated;
        expect(unauthenticated.pinSet, isTrue);
        expect(
          container.read(authNotifierProvider.notifier).isBiometricAvailable,
          isFalse,
        );
      },
    );

    test(
      'authenticateWithBiometrics maps BiometricNotAvailableFailure',
      () async {
        fakePinAuth.setStoredPin('1234');
        when(() => mockLocalAuth.authenticate()).thenAnswer(
          (_) async => const Err<bool>(BiometricNotAvailableFailure()),
        );

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithBiometrics();

        expect(states, [isA<AuthError>()]);
        final error = states.single as AuthError;
        expect(error.failure, isA<BiometricNotAvailableFailure>());
        expect(
          error.failure.message,
          'Biometric authentication is not available on this device.',
        );
      },
    );

    test(
      'signOut when already unauthenticated keeps unauthenticated state',
      () async {
        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container.read(authNotifierProvider.notifier).initialize();
        container.read(authNotifierProvider.notifier).signOut();

        expect(
          container.read(authNotifierProvider),
          isA<AuthUnauthenticated>(),
        );
        final unauthenticated =
            container.read(authNotifierProvider) as AuthUnauthenticated;
        expect(unauthenticated.pinSet, isFalse);
      },
    );

    test('authenticateWithPin emits error when setPin fails', () async {
      fakePinAuth = FakePinAuthService(
        failureOnSet: const UnknownFailure('Storage error'),
      );
      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin('5678');

      expect(states, [isA<AuthError>()]);
      final error = states.single as AuthError;
      expect(error.failure, isA<UnknownFailure>());
    });

    test('signOut returns state to unauthenticated', () async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockLocalAuth.authenticate(),
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
      final unauthenticated = states.last as AuthUnauthenticated;
      expect(unauthenticated.pinSet, isTrue);
    });

    test(
      'initialize emits AuthError with AuthCancelledFailure when biometric auth is cancelled',
      () async {
        fakePinAuth.setStoredPin('1234');
        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenAnswer((_) async => true);
        when(
          () => mockLocalAuth.authenticate(),
        ).thenAnswer((_) async => const Err<bool>(AuthCancelledFailure()));

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container.read(authNotifierProvider.notifier).initialize();

        expect(states, [isA<AuthError>()]);
        final error = states.single as AuthError;
        expect(error.failure, isA<AuthCancelledFailure>());
        expect(error.failure.message, 'Authentication was cancelled.');
      },
    );

    test(
      'initialize emits AuthError with AuthFailedFailure when biometric auth fails',
      () async {
        fakePinAuth.setStoredPin('1234');
        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenAnswer((_) async => true);
        when(
          () => mockLocalAuth.authenticate(),
        ).thenAnswer((_) async => const Err<bool>(AuthFailedFailure()));

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container.read(authNotifierProvider.notifier).initialize();

        expect(states, [isA<AuthError>()]);
        final error = states.single as AuthError;
        expect(error.failure, isA<AuthFailedFailure>());
        expect(
          error.failure.message,
          'Authentication failed. Please try again.',
        );
      },
    );

    test(
      'initialize does not attempt biometrics when no PIN is set even if biometrics are available',
      () async {
        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenAnswer((_) async => true);

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container.read(authNotifierProvider.notifier).initialize();

        expect(states, [isA<AuthUnauthenticated>()]);
        final unauthenticated = states.single as AuthUnauthenticated;
        expect(unauthenticated.pinSet, isFalse);
        verifyNever(() => mockLocalAuth.authenticate());
      },
    );

    test(
      'authenticateWithBiometrics attempts local auth and succeeds when PIN was removed',
      () async {
        fakePinAuth.setStoredPin('1234');
        when(
          () => mockLocalAuth.authenticate(),
        ).thenAnswer((_) async => const Success<bool>(true));

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        fakePinAuth.clearStoredPin();
        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithBiometrics();

        expect(states, [isA<AuthAuthenticated>()]);
        expect(container.read(authNotifierProvider.notifier).isPinSet, isFalse);
      },
    );

    test(
      'authenticateWithBiometrics attempts local auth and fails when PIN was removed',
      () async {
        fakePinAuth.setStoredPin('1234');
        when(
          () => mockLocalAuth.authenticate(),
        ).thenAnswer((_) async => const Err<bool>(AuthFailedFailure()));

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        fakePinAuth.clearStoredPin();
        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithBiometrics();

        expect(states, [isA<AuthError>()]);
        final error = states.single as AuthError;
        expect(error.failure, isA<AuthFailedFailure>());
      },
    );

    test(
      'signOut during active authenticateWithPin ends unauthenticated',
      () async {
        fakePinAuth.setStoredPin('1234');
        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenAnswer((_) async => false);
        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container.read(authNotifierProvider.notifier).initialize();
        states.clear();

        final authFuture = container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('1234');
        container.read(authNotifierProvider.notifier).signOut();
        await authFuture;

        expect(
          container.read(authNotifierProvider),
          isA<AuthUnauthenticated>(),
        );
        final unauthenticated =
            container.read(authNotifierProvider) as AuthUnauthenticated;
        expect(unauthenticated.pinSet, isTrue);
        expect(states.whereType<AuthError>().length, 0);
        expect(
          container.read(authNotifierProvider.notifier).isAuthenticating,
          isFalse,
        );
      },
    );

    test(
      'multiple rapid signOut calls do not throw or emit extra states',
      () async {
        fakePinAuth.setStoredPin('1234');
        when(
          () => mockLocalAuth.authenticate(),
        ).thenAnswer((_) async => const Success<bool>(true));

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithBiometrics();
        container.read(authNotifierProvider.notifier).signOut();
        container.read(authNotifierProvider.notifier).signOut();
        container.read(authNotifierProvider.notifier).signOut();

        expect(states, [isA<AuthAuthenticated>(), isA<AuthUnauthenticated>()]);
        final unauthenticated = states.last as AuthUnauthenticated;
        expect(unauthenticated.pinSet, isTrue);
      },
    );

    test(
      'authenticateWithBiometrics attempts local auth and authenticates when no PIN is set',
      () async {
        when(
          () => mockLocalAuth.authenticate(),
        ).thenAnswer((_) async => const Success<bool>(true));

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithBiometrics();

        expect(states, [isA<AuthAuthenticated>()]);
        expect(container.read(authNotifierProvider.notifier).isPinSet, isFalse);
      },
    );

    test(
      'authenticateWithPin rapid calls produce deterministic authenticated state',
      () async {
        final raceyPinAuth = RaceyFakePinAuthService();
        final container = ProviderContainer(
          overrides: [
            localAuthServiceProvider.overrideWithValue(mockLocalAuth),
            pinAuthServiceProvider.overrideWithValue(raceyPinAuth),
          ],
        );
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        final futures = <Future<void>>[
          container
              .read(authNotifierProvider.notifier)
              .authenticateWithPin('1234'),
          container
              .read(authNotifierProvider.notifier)
              .authenticateWithPin('1234'),
          container
              .read(authNotifierProvider.notifier)
              .authenticateWithPin('1234'),
        ];

        await Future.wait(futures);

        expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
        expect(container.read(authNotifierProvider.notifier).isPinSet, isTrue);
        expect(states.whereType<AuthAuthenticated>().length, 1);
        expect(states.whereType<AuthError>().length, 0);
        expect(raceyPinAuth.setPinCallCount, 1);
      },
    );

    test('initialize called twice does not emit duplicate states', () async {
      when(
        () => mockLocalAuth.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container.read(authNotifierProvider.notifier).initialize();
      await container.read(authNotifierProvider.notifier).initialize();

      expect(states, [isA<AuthUnauthenticated>()]);
      final unauthenticated = states.single as AuthUnauthenticated;
      expect(unauthenticated.pinSet, isFalse);
    });

    test(
      'authenticateWithBiometrics concurrent calls emit single state change',
      () async {
        fakePinAuth.setStoredPin('1234');
        final completers = <Completer<void>>[
          Completer<void>(),
          Completer<void>(),
        ];
        var callIndex = 0;
        when(() => mockLocalAuth.authenticate()).thenAnswer((_) async {
          final completer = completers[callIndex];
          callIndex++;
          await completer.future;
          return const Success<bool>(true);
        });

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        final futures = <Future<void>>[
          container
              .read(authNotifierProvider.notifier)
              .authenticateWithBiometrics(),
          container
              .read(authNotifierProvider.notifier)
              .authenticateWithBiometrics(),
        ];
        for (final completer in completers) {
          completer.complete();
        }
        await Future.wait(futures);

        expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
        expect(states.whereType<AuthAuthenticated>().length, 1);
      },
    );

    test('signOut before initialize completes does not throw', () async {
      when(
        () => mockLocalAuth.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(authNotifierProvider.notifier).signOut();

      expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
      final unauthenticated =
          container.read(authNotifierProvider) as AuthUnauthenticated;
      expect(unauthenticated.pinSet, isFalse);
    });

    test(
      'authenticateWithPin with setPin failure emits AuthError and leaves pinSet unchanged',
      () async {
        fakePinAuth = FakePinAuthService(
          failureOnSet: const UnknownFailure('Storage error'),
        );
        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('5678');

        expect(states, [isA<AuthError>()]);
        final error = states.single as AuthError;
        expect(error.failure, isA<UnknownFailure>());
        expect(container.read(authNotifierProvider.notifier).isPinSet, isFalse);
      },
    );

    test('locks PIN entry after max failed attempts', () async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockLocalAuth.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container.read(authNotifierProvider.notifier).initialize();
      states.clear();

      for (var i = 0; i < 5; i++) {
        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('0000');
      }

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin('1234');

      final lockoutErrors = states.whereType<AuthError>().where(
        (e) => e.failure is PinLockedFailure,
      );
      expect(lockoutErrors.length, 1);
      final failure = lockoutErrors.single.failure as PinLockedFailure;
      expect(failure.remainingSeconds, greaterThan(0));
      expect(failure.remainingSeconds, lessThanOrEqualTo(60));
      expect(container.read(authNotifierProvider), isA<AuthError>());
    });

    test('successful PIN entry resets failed attempt lockout', () async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockLocalAuth.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final container = makeContainer();
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container.read(authNotifierProvider.notifier).initialize();
      states.clear();

      for (var i = 0; i < 4; i++) {
        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('0000');
      }
      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin('1234');

      expect(states.whereType<AuthAuthenticated>().length, 1);

      container.read(authNotifierProvider.notifier).signOut();
      states.clear();

      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin('0000');

      expect(states, [isA<AuthError>()]);
      final error = states.single as AuthError;
      expect(error.failure, isA<PinMismatchFailure>());
    });
  });
}
