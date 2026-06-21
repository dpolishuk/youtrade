import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/auth/local_auth_service_impl.dart';
import 'package:youtrade/domain/auth/auth_failure.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';

class _MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
        useErrorDialogs: false,
      ),
    );
  });

  group('LocalAuthServiceImpl', () {
    late _MockLocalAuthentication mockLocalAuth;
    late LocalAuthService service;

    setUp(() {
      mockLocalAuth = _MockLocalAuthentication();
      service = LocalAuthServiceImpl(localAuthentication: mockLocalAuth);
    });

    group('canCheckBiometrics', () {
      test('returns true when biometrics and device are supported', () async {
        when(
          () => mockLocalAuth.canCheckBiometrics,
        ).thenAnswer((_) async => true);
        when(
          () => mockLocalAuth.isDeviceSupported(),
        ).thenAnswer((_) async => true);

        expect(await service.canCheckBiometrics(), isTrue);
      });

      test('returns false when biometrics unavailable', () async {
        when(
          () => mockLocalAuth.canCheckBiometrics,
        ).thenAnswer((_) async => false);
        when(
          () => mockLocalAuth.isDeviceSupported(),
        ).thenAnswer((_) async => true);

        expect(await service.canCheckBiometrics(), isFalse);
      });

      test('returns false when device not supported', () async {
        when(
          () => mockLocalAuth.canCheckBiometrics,
        ).thenAnswer((_) async => true);
        when(
          () => mockLocalAuth.isDeviceSupported(),
        ).thenAnswer((_) async => false);

        expect(await service.canCheckBiometrics(), isFalse);
      });

      test('returns false when platform call throws', () async {
        when(
          () => mockLocalAuth.canCheckBiometrics,
        ).thenThrow(Exception('biometrics unavailable'));

        expect(await service.canCheckBiometrics(), isFalse);
      });
    });

    group('authenticate', () {
      test('returns Success(true) when user authenticates', () async {
        when(
          () => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => true);

        final result = await service.authenticate();

        expect(result, isA<Success<bool>>());
        final didAuthenticate = result.fold((_) => false, (value) => value);
        expect(didAuthenticate, isTrue);
      });

      test('returns AuthCancelledFailure when user cancels', () async {
        when(
          () => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => false);

        final result = await service.authenticate();

        expect(result, isA<Err<bool>>());
        final failure = result.fold((f) => f, (_) => fail('expected failure'));
        expect(failure, isA<AuthCancelledFailure>());
      });

      test('maps notAvailable to BiometricNotAvailableFailure', () async {
        when(
          () => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            options: any(named: 'options'),
          ),
        ).thenThrow(PlatformException(code: auth_error.notAvailable));

        final result = await service.authenticate();

        expect(result, isA<Err<bool>>());
        final failure = result.fold((f) => f, (_) => fail('expected failure'));
        expect(failure, isA<BiometricNotAvailableFailure>());
      });

      test('maps notEnrolled to BiometricNotAvailableFailure', () async {
        when(
          () => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            options: any(named: 'options'),
          ),
        ).thenThrow(PlatformException(code: auth_error.notEnrolled));

        final result = await service.authenticate();

        expect(result, isA<Err<bool>>());
        final failure = result.fold((f) => f, (_) => fail('expected failure'));
        expect(failure, isA<BiometricNotAvailableFailure>());
      });

      test('maps passcodeNotSet to BiometricNotAvailableFailure', () async {
        when(
          () => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            options: any(named: 'options'),
          ),
        ).thenThrow(PlatformException(code: auth_error.passcodeNotSet));

        final result = await service.authenticate();

        expect(result, isA<Err<bool>>());
        final failure = result.fold((f) => f, (_) => fail('expected failure'));
        expect(failure, isA<BiometricNotAvailableFailure>());
      });

      test('maps lockedOut to AuthFailedFailure', () async {
        when(
          () => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            options: any(named: 'options'),
          ),
        ).thenThrow(PlatformException(code: auth_error.lockedOut));

        final result = await service.authenticate();

        expect(result, isA<Err<bool>>());
        final failure = result.fold((f) => f, (_) => fail('expected failure'));
        expect(failure, isA<AuthFailedFailure>());
      });

      test('maps permanentlyLockedOut to AuthFailedFailure', () async {
        when(
          () => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            options: any(named: 'options'),
          ),
        ).thenThrow(PlatformException(code: auth_error.permanentlyLockedOut));

        final result = await service.authenticate();

        expect(result, isA<Err<bool>>());
        final failure = result.fold((f) => f, (_) => fail('expected failure'));
        expect(failure, isA<AuthFailedFailure>());
      });

      test('maps unknown PlatformException to AuthCancelledFailure', () async {
        when(
          () => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            options: any(named: 'options'),
          ),
        ).thenThrow(PlatformException(code: 'user_cancel'));

        final result = await service.authenticate();

        expect(result, isA<Err<bool>>());
        final failure = result.fold((f) => f, (_) => fail('expected failure'));
        expect(failure, isA<AuthCancelledFailure>());
      });

      test('returns AuthFailedFailure on unexpected exception', () async {
        when(
          () => mockLocalAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            authMessages: any(named: 'authMessages'),
            options: any(named: 'options'),
          ),
        ).thenThrow(Exception('unexpected'));

        final result = await service.authenticate();

        expect(result, isA<Err<bool>>());
        final failure = result.fold((f) => f, (_) => fail('expected failure'));
        expect(failure, isA<AuthFailedFailure>());
      });
    });
  });
}
