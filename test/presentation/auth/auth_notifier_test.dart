import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/auth/secure_pin_auth_service.dart';
import 'package:youtrade/domain/auth/auth_failure.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/presentation/auth/auth_guard_provider.dart';
import 'package:youtrade/presentation/auth/auth_notifier.dart';
import 'package:youtrade/presentation/auth/auth_state.dart';

import '../../fakes/fake_pin_auth_service.dart';
import '../../fakes/racey_fake_pin_auth_service.dart';

class MockLocalAuthService extends Mock implements LocalAuthService {}

class _MockPrefs extends Mock implements SharedPreferencesAsync {}

void main() {
  late MockLocalAuthService mockLocalAuth;
  late FakePinAuthService fakePinAuth;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
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
      'initialize transitions to PIN entry when biometrics are available',
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

        expect(states, [isA<AuthUnauthenticated>()]);
        final unauthenticated = states.single as AuthUnauthenticated;
        expect(unauthenticated.pinSet, isTrue);
        verifyNever(() => mockLocalAuth.authenticate());
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
      'authenticateWithBiometrics emits AuthError when authenticate throws unexpectedly',
      () async {
        fakePinAuth.setStoredPin('1234');
        when(
          () => mockLocalAuth.authenticate(),
        ).thenThrow(Exception('local auth crashed'));

        final container = makeContainer();
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithBiometrics();

        expect(states, [isA<AuthError>()]);
        final error = states.single as AuthError;
        expect(error.failure, isA<UnknownFailure>());
        expect(
          container.read(authNotifierProvider.notifier).isAuthenticating,
          isFalse,
        );
      },
    );

    test(
      'authenticateWithBiometrics emits AuthError when isPinSet throws unexpectedly',
      () async {
        final throwingPinAuth = FakePinAuthService(
          exceptionOnIsPinSet: Exception('storage corrupted'),
        );
        final container = ProviderContainer(
          overrides: [
            localAuthServiceProvider.overrideWithValue(mockLocalAuth),
            pinAuthServiceProvider.overrideWithValue(throwingPinAuth),
          ],
        );
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithBiometrics();

        expect(states, [isA<AuthError>()]);
        final error = states.single as AuthError;
        expect(error.failure, isA<UnknownFailure>());
        expect(
          container.read(authNotifierProvider.notifier).isAuthenticating,
          isFalse,
        );
      },
    );

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
      'authenticateWithPin emits AuthError when setPin throws unexpectedly',
      () async {
        final throwingPinAuth = FakePinAuthService(
          exceptionOnSet: Exception('storage write failed'),
        );
        final container = ProviderContainer(
          overrides: [
            localAuthServiceProvider.overrideWithValue(mockLocalAuth),
            pinAuthServiceProvider.overrideWithValue(throwingPinAuth),
          ],
        );
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
        expect(
          container.read(authNotifierProvider.notifier).isAuthenticating,
          isFalse,
        );
      },
    );

    test(
      'authenticateWithPin emits AuthError when authenticatePin throws unexpectedly',
      () async {
        final throwingPinAuth = FakePinAuthService(
          initialPin: '1234',
          exceptionOnAuthenticatePin: Exception('crypto module crashed'),
        );
        final container = ProviderContainer(
          overrides: [
            localAuthServiceProvider.overrideWithValue(mockLocalAuth),
            pinAuthServiceProvider.overrideWithValue(throwingPinAuth),
          ],
        );
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('1234');

        expect(states, [isA<AuthError>()]);
        final error = states.single as AuthError;
        expect(error.failure, isA<UnknownFailure>());
        expect(container.read(authNotifierProvider.notifier).isPinSet, isTrue);
        expect(
          container.read(authNotifierProvider.notifier).isAuthenticating,
          isFalse,
        );
      },
    );

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
      'initialize emits AuthUnauthenticated when isPinSet throws unexpectedly',
      () async {
        final throwingPinAuth = FakePinAuthService(
          exceptionOnIsPinSet: Exception('storage corrupted'),
        );
        final container = ProviderContainer(
          overrides: [
            localAuthServiceProvider.overrideWithValue(mockLocalAuth),
            pinAuthServiceProvider.overrideWithValue(throwingPinAuth),
          ],
        );
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
      expect(failure.remainingSeconds, lessThanOrEqualTo(15 * 60));
      expect(container.read(authNotifierProvider), isA<AuthError>());
    });

    test('lockout expires and allows retry with correct PIN', () async {
      fakePinAuth.setStoredPin('1234');
      when(
        () => mockLocalAuth.canCheckBiometrics(),
      ).thenAnswer((_) async => false);

      final startTime = DateTime.utc(2026, 1, 1, 12, 0, 0);
      var currentTime = startTime;
      final container = ProviderContainer(
        overrides: [
          localAuthServiceProvider.overrideWithValue(mockLocalAuth),
          pinAuthServiceProvider.overrideWithValue(fakePinAuth),
          authNotifierProvider.overrideWith(
            (ref) => AuthNotifier(
              mockLocalAuth,
              fakePinAuth,
              clock: () => currentTime,
            ),
          ),
        ],
      );
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

      expect(container.read(authNotifierProvider), isA<AuthError>());

      currentTime = startTime.add(const Duration(minutes: 15, seconds: 1));
      states.clear();
      await container
          .read(authNotifierProvider.notifier)
          .authenticateWithPin('1234');

      expect(states, [isA<AuthAuthenticated>()]);
      expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
    });

    test('initialize treats storage read error as no PIN configured', () async {
      final mockPrefs = _MockPrefs();
      when(
        () => mockPrefs.getString(any()),
      ).thenThrow(Exception('secure storage read failed'));
      final securePinAuth = SecurePinAuthService(prefs: mockPrefs);
      final container = ProviderContainer(
        overrides: [
          localAuthServiceProvider.overrideWithValue(mockLocalAuth),
          pinAuthServiceProvider.overrideWithValue(securePinAuth),
        ],
      );
      addTearDown(container.dispose);
      final states = <AuthState>[];
      container.listen(authNotifierProvider, (_, state) => states.add(state));

      await container.read(authNotifierProvider.notifier).initialize();

      expect(states, [isA<AuthUnauthenticated>()]);
      final unauthenticated = states.single as AuthUnauthenticated;
      expect(unauthenticated.pinSet, isFalse);
      expect(container.read(authNotifierProvider.notifier).isPinSet, isFalse);
    });

    test(
      'authenticateWithPin empty string emits PinValidationFailure when no PIN is set',
      () async {
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
        expect(container.read(authNotifierProvider.notifier).isPinSet, isFalse);
      },
    );

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

    test(
      'successful biometrics resets PIN lockout and allows PIN entry',
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

        for (var i = 0; i < 5; i++) {
          await container
              .read(authNotifierProvider.notifier)
              .authenticateWithPin('0000');
        }

        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('1234');

        expect(container.read(authNotifierProvider), isA<AuthError>());
        final firstError = container.read(authNotifierProvider) as AuthError;
        expect(firstError.failure, isA<PinLockedFailure>());

        states.clear();
        when(
          () => mockLocalAuth.authenticate(),
        ).thenAnswer((_) async => const Success<bool>(true));
        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithBiometrics();

        expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());

        container.read(authNotifierProvider.notifier).signOut();
        states.clear();

        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('1234');

        expect(states, [isA<AuthAuthenticated>()]);
      },
    );

    group('with SecurePinAuthService', () {
      ProviderContainer makeSecureContainer(SecurePinAuthService svc) {
        return ProviderContainer(
          overrides: [
            localAuthServiceProvider.overrideWithValue(mockLocalAuth),
            pinAuthServiceProvider.overrideWithValue(svc),
          ],
        );
      }

      test('locks PIN entry after max failed attempts', () async {
        final service = SecurePinAuthService();
        await service.setPin('1234');

        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = makeSecureContainer(service);
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

      test('emits AuthError when setPin fails due to storage error', () async {
        final mockPrefs = _MockPrefs();
        when(() => mockPrefs.getString(any())).thenAnswer((_) async => null);
        when(
          () => mockPrefs.setString(any(), any()),
        ).thenThrow(Exception('write failed'));
        final service = SecurePinAuthService(prefs: mockPrefs);

        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final container = makeSecureContainer(service);
        addTearDown(container.dispose);
        final states = <AuthState>[];
        container.listen(authNotifierProvider, (_, state) => states.add(state));

        await container
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('5678');

        expect(states, [isA<AuthError>()]);
        final error = states.single as AuthError;
        expect(error.failure, isA<UnknownFailure>());
        expect(error.failure.message, contains('Failed to store PIN'));
        expect(container.read(authNotifierProvider.notifier).isPinSet, isFalse);
      });

      test(
        'lockout remains active after app restart with persisted state',
        () async {
          final service = SecurePinAuthService();
          await service.setPin('1234');

          when(
            () => mockLocalAuth.canCheckBiometrics(),
          ).thenAnswer((_) async => false);

          final firstContainer = makeSecureContainer(service);
          addTearDown(firstContainer.dispose);
          final firstStates = <AuthState>[];
          firstContainer.listen(
            authNotifierProvider,
            (_, state) => firstStates.add(state),
          );

          await firstContainer.read(authNotifierProvider.notifier).initialize();
          firstStates.clear();

          for (var i = 0; i < 5; i++) {
            await firstContainer
                .read(authNotifierProvider.notifier)
                .authenticateWithPin('0000');
          }

          await firstContainer
              .read(authNotifierProvider.notifier)
              .authenticateWithPin('1234');

          expect(firstContainer.read(authNotifierProvider), isA<AuthError>());
          final firstError =
              firstContainer.read(authNotifierProvider) as AuthError;
          expect(firstError.failure, isA<PinLockedFailure>());

          firstContainer.dispose();

          final secondService = SecurePinAuthService();
          final secondContainer = makeSecureContainer(secondService);
          addTearDown(secondContainer.dispose);
          final secondStates = <AuthState>[];
          secondContainer.listen(
            authNotifierProvider,
            (_, state) => secondStates.add(state),
          );

          await secondContainer
              .read(authNotifierProvider.notifier)
              .initialize();
          secondStates.clear();

          await secondContainer
              .read(authNotifierProvider.notifier)
              .authenticateWithPin('1234');

          expect(secondStates, [isA<AuthError>()]);
          final secondError = secondStates.single as AuthError;
          expect(secondError.failure, isA<PinLockedFailure>());
          expect(
            (secondError.failure as PinLockedFailure).remainingSeconds,
            greaterThan(0),
          );
        },
      );

      test('expired lockout allows PIN entry after app restart', () async {
        final service = SecurePinAuthService();
        await service.setPin('1234');

        when(
          () => mockLocalAuth.canCheckBiometrics(),
        ).thenAnswer((_) async => false);

        final startTime = DateTime.utc(2026, 1, 1, 12, 0, 0);
        var currentTime = startTime;

        AuthNotifier createNotifier(SecurePinAuthService svc) =>
            AuthNotifier(mockLocalAuth, svc, clock: () => currentTime);

        final firstContainer = ProviderContainer(
          overrides: [
            localAuthServiceProvider.overrideWithValue(mockLocalAuth),
            pinAuthServiceProvider.overrideWithValue(service),
            authNotifierProvider.overrideWith((ref) => createNotifier(service)),
          ],
        );
        addTearDown(firstContainer.dispose);
        final firstStates = <AuthState>[];
        firstContainer.listen(
          authNotifierProvider,
          (_, state) => firstStates.add(state),
        );

        await firstContainer.read(authNotifierProvider.notifier).initialize();
        firstStates.clear();

        for (var i = 0; i < 5; i++) {
          await firstContainer
              .read(authNotifierProvider.notifier)
              .authenticateWithPin('0000');
        }

        await firstContainer
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('1234');

        expect(firstContainer.read(authNotifierProvider), isA<AuthError>());
        final firstError =
            firstContainer.read(authNotifierProvider) as AuthError;
        expect(firstError.failure, isA<PinLockedFailure>());

        firstContainer.dispose();

        currentTime = startTime.add(const Duration(minutes: 15, seconds: 1));

        final secondService = SecurePinAuthService();
        final secondContainer = ProviderContainer(
          overrides: [
            localAuthServiceProvider.overrideWithValue(mockLocalAuth),
            pinAuthServiceProvider.overrideWithValue(secondService),
            authNotifierProvider.overrideWith(
              (ref) => createNotifier(secondService),
            ),
          ],
        );
        addTearDown(secondContainer.dispose);
        final secondStates = <AuthState>[];
        secondContainer.listen(
          authNotifierProvider,
          (_, state) => secondStates.add(state),
        );

        await secondContainer.read(authNotifierProvider.notifier).initialize();
        secondStates.clear();

        await secondContainer
            .read(authNotifierProvider.notifier)
            .authenticateWithPin('1234');

        expect(secondStates, [isA<AuthAuthenticated>()]);
        expect(
          secondContainer.read(authNotifierProvider),
          isA<AuthAuthenticated>(),
        );
      });

      test(
        'concurrent authenticateWithPin calls produce deterministic authenticated state',
        () async {
          final service = SecurePinAuthService();

          when(
            () => mockLocalAuth.canCheckBiometrics(),
          ).thenAnswer((_) async => false);

          final container = makeSecureContainer(service);
          addTearDown(container.dispose);
          final states = <AuthState>[];
          container.listen(
            authNotifierProvider,
            (_, state) => states.add(state),
          );

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

          expect(
            container.read(authNotifierProvider),
            isA<AuthAuthenticated>(),
          );
          expect(
            container.read(authNotifierProvider.notifier).isPinSet,
            isTrue,
          );
          expect(states.whereType<AuthAuthenticated>().length, 1);
          expect(states.whereType<AuthError>().length, 0);
        },
      );
    });
  });
}
