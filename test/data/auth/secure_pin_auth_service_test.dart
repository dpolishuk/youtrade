import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/auth/secure_pin_auth_service.dart';
import 'package:youtrade/domain/auth/auth_failure.dart';

class _MockPrefs extends Mock implements SharedPreferencesAsync {}

void main() {
  group('SecurePinAuthService', () {
    late SecurePinAuthService service;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      service = SecurePinAuthService();
    });

    group('security configuration', () {
      test('uses PBKDF2 key derivation', () {
        expect(SecurePinAuthService.pbkdf2Iterations, greaterThan(1000));
      });
    });

    group('isPinSet', () {
      test('returns false when no PIN hash is stored', () async {
        expect(await service.isPinSet(), isFalse);
      });

      test('returns true when a PIN hash is stored', () async {
        await service.setPin('1234');

        expect(await service.isPinSet(), isTrue);
      });

      test('returns false when stored hash is empty', () async {
        final prefs = SharedPreferencesAsync();
        await prefs.setString('pin_hash', '');

        expect(await service.isPinSet(), isFalse);
      });

      test('returns false when storage read throws', () async {
        final mockPrefs = _MockPrefs();
        when(
          () => mockPrefs.getString('pin_hash'),
        ).thenThrow(Exception('read failed'));
        service = SecurePinAuthService(prefs: mockPrefs);

        expect(await service.isPinSet(), isFalse);
      });
    });

    group('setPin', () {
      test('stores a salted hash of the PIN', () async {
        final result = await service.setPin('1234');

        expect(result, isA<Success<void>>());
        final prefs = SharedPreferencesAsync();
        final hash = await prefs.getString('pin_hash');
        final salt = await prefs.getString('pin_salt');
        expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(salt, matches(RegExp(r'^[A-Za-z0-9+/]{22}==$')));
        expect(hash, isNot(equals('1234')));
      });

      test('rejects PINs shorter than 4 digits', () async {
        final result = await service.setPin('123');

        expect(result, isA<Err<void>>());
        final failure = (result as Err<void>).failure as PinValidationFailure;
        expect(failure.message, 'PIN must be exactly 4 digits.');
      });

      test('rejects empty PIN', () async {
        final result = await service.setPin('');

        expect(result, isA<Err<void>>());
        final failure = (result as Err<void>).failure as PinValidationFailure;
        expect(failure.message, 'PIN must be exactly 4 digits.');
      });

      test('rejects PINs longer than 4 digits', () async {
        final result = await service.setPin('12345');

        expect(result, isA<Err<void>>());
        final failure = (result as Err<void>).failure as PinValidationFailure;
        expect(failure.message, 'PIN must be exactly 4 digits.');
      });

      test('reuses existing salt when updating PIN', () async {
        await service.setPin('1234');
        final prefs = SharedPreferencesAsync();
        final firstSalt = await prefs.getString('pin_salt');

        await service.setPin('5678');
        final secondSalt = await prefs.getString('pin_salt');

        expect(secondSalt, equals(firstSalt));
      });

      test('rejects PINs longer than 4 digits (6 chars)', () async {
        final result = await service.setPin('123456');

        expect(result, isA<Err<void>>());
        final failure = (result as Err<void>).failure as PinValidationFailure;
        expect(failure.message, 'PIN must be exactly 4 digits.');
      });

      test('concurrent setPin calls produce deterministic final PIN', () async {
        final results = await Future.wait([
          service.setPin('1111'),
          service.setPin('2222'),
          service.setPin('3333'),
        ]);

        final successCount = results.whereType<Success<void>>().length;
        expect(successCount, 1);

        final candidates = ['1111', '2222', '3333'];
        final matchingCandidates = <String>[];
        for (final pin in candidates) {
          if (await service.authenticatePin(pin)) {
            matchingCandidates.add(pin);
          }
        }
        expect(matchingCandidates.length, 1);
      });

      test('returns UnknownFailure when storage write fails', () async {
        final mockPrefs = _MockPrefs();
        when(() => mockPrefs.getString(any())).thenAnswer((_) async => null);
        when(
          () => mockPrefs.setString(any(), any()),
        ).thenThrow(Exception('write failed'));
        service = SecurePinAuthService(prefs: mockPrefs);

        final result = await service.setPin('1234');

        expect(result, isA<Err<void>>());
        final failure = (result as Err<void>).failure as UnknownFailure;
        expect(failure.message, contains('Failed to store PIN'));
      });

      test('accepts PIN with leading zeros', () async {
        final result = await service.setPin('0012');

        expect(result, isA<Success<void>>());
        expect(await service.authenticatePin('0012'), isTrue);
        expect(await service.authenticatePin('12'), isFalse);
      });

      test('rejects PIN with non-digit characters', () async {
        final result = await service.setPin('12a4');

        expect(result, isA<Err<void>>());
        final failure = (result as Err<void>).failure as PinValidationFailure;
        expect(failure.message, 'PIN must contain only digits.');
      });
    });

    group('authenticatePin', () {
      test('returns true for the correct PIN', () async {
        await service.setPin('1234');

        expect(await service.authenticatePin('1234'), isTrue);
      });

      test('returns false for an incorrect PIN', () async {
        await service.setPin('1234');

        expect(await service.authenticatePin('0000'), isFalse);
      });

      test('sets PIN when none is configured and returns true', () async {
        expect(await service.isPinSet(), isFalse);

        final authenticated = await service.authenticatePin('5678');

        expect(authenticated, isTrue);
        expect(await service.isPinSet(), isTrue);
        expect(await service.authenticatePin('5678'), isTrue);
      });

      test('returns false for short PIN', () async {
        await service.setPin('1234');

        expect(await service.authenticatePin('12'), isFalse);
      });

      test('returns false for PIN longer than 4 digits', () async {
        await service.setPin('1234');

        expect(await service.authenticatePin('12345'), isFalse);
      });

      test('returns false for short PIN when none is set', () async {
        final authenticated = await service.authenticatePin('12');

        expect(authenticated, isFalse);
        expect(await service.isPinSet(), isFalse);
      });

      test('uses salt to produce different hashes for the same PIN', () async {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();

        final serviceA = SecurePinAuthService();
        await serviceA.setPin('1234');
        final prefsA = SharedPreferencesAsync();
        final hashA = await prefsA.getString('pin_hash');

        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();

        final serviceB = SecurePinAuthService();
        await serviceB.setPin('1234');
        final prefsB = SharedPreferencesAsync();
        final hashB = await prefsB.getString('pin_hash');

        expect(hashA, isNot(equals(hashB)));
      });

      test(
        'returns false when stored hash exists but salt is missing',
        () async {
          await service.setPin('1234');
          final prefs = SharedPreferencesAsync();
          await prefs.remove('pin_salt');

          expect(await service.authenticatePin('1234'), isFalse);
        },
      );

      test('returns false for PIN with non-digit characters', () async {
        await service.setPin('1234');

        expect(await service.authenticatePin('12a4'), isFalse);
      });

      test('returns false when stored hash exists but salt is empty', () async {
        await service.setPin('1234');
        final prefs = SharedPreferencesAsync();
        await prefs.setString('pin_salt', '');

        expect(await service.authenticatePin('1234'), isFalse);
      });

      test(
        'returns false when storage read throws during authenticate',
        () async {
          await service.setPin('1234');
          final mockPrefs = _MockPrefs();
          when(() => mockPrefs.getString(any())).thenThrow(Exception('boom'));
          service = SecurePinAuthService(prefs: mockPrefs);

          expect(await service.authenticatePin('1234'), isFalse);
        },
      );

      test('returns false when stored hash is corrupted', () async {
        final prefs = SharedPreferencesAsync();
        await prefs.setString('pin_hash', 'not-a-valid-hash');
        await prefs.setString('pin_salt', base64Salt);

        expect(await service.authenticatePin('1234'), isFalse);
      });
    });
  });
}

const base64Salt = 'AAAAAAAAAAAAAAAAAAAAAA==';
