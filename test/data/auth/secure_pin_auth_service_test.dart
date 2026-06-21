import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/data/auth/secure_pin_auth_service.dart';
import 'package:youtrade/domain/auth/auth_failure.dart';

class _FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String?> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

class _ThrowingWriteStorage extends _FakeSecureStorage {
  _ThrowingWriteStorage(this.exception);

  final Exception exception;

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw exception;
  }
}

class _ThrowingReadStorage extends _FakeSecureStorage {
  _ThrowingReadStorage(this.exception);

  final Exception exception;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw exception;
  }
}

String _expectedHash(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt$pin')).toString();

void main() {
  group('SecurePinAuthService', () {
    late _FakeSecureStorage storage;
    late SecurePinAuthService service;

    setUp(() {
      storage = _FakeSecureStorage();
      service = SecurePinAuthService(storage: storage);
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
        await storage.write(key: 'pin_hash', value: '');

        expect(await service.isPinSet(), isFalse);
      });

      test('returns false when storage read throws', () async {
        service = SecurePinAuthService(
          storage: _ThrowingReadStorage(Exception('read failed')),
        );

        expect(await service.isPinSet(), isFalse);
      });
    });

    group('setPin', () {
      test('stores a salted hash of the PIN', () async {
        final result = await service.setPin('1234');

        expect(result, isA<Success<void>>());
        final hash = await storage.read(key: 'pin_hash');
        final salt = await storage.read(key: 'pin_salt');
        expect(hash, isNotNull);
        expect(hash, isNotEmpty);
        expect(salt, isNotNull);
        expect(salt, isNotEmpty);
        expect(hash, isNot(equals('1234')));
      });

      test('rejects PINs shorter than 4 digits', () async {
        final result = await service.setPin('123');

        expect(result, isA<Err<void>>());
        final failure = (result as Err<void>).failure as PinValidationFailure;
        expect(failure.message, 'PIN must be at least 4 digits.');
      });

      test('rejects empty PIN', () async {
        final result = await service.setPin('');

        expect(result, isA<Err<void>>());
        final failure = (result as Err<void>).failure as PinValidationFailure;
        expect(failure.message, 'PIN must be at least 4 digits.');
      });

      test('reuses existing salt when updating PIN', () async {
        await service.setPin('1234');
        final firstSalt = await storage.read(key: 'pin_salt');

        final result = await service.setPin('5678');
        final secondSalt = await storage.read(key: 'pin_salt');

        expect(result, isA<Success<void>>());
        expect(secondSalt, equals(firstSalt));
      });

      test(
        'accepts PINs longer than 4 digits and stores salted hash',
        () async {
          final result = await service.setPin('123456');

          expect(result, isA<Success<void>>());
          final hash = await storage.read(key: 'pin_hash');
          final salt = await storage.read(key: 'pin_salt');
          expect(hash, isNotNull);
          expect(hash, isNotEmpty);
          expect(salt, isNotNull);
          expect(salt, isNotEmpty);
          expect(hash, isNot(equals('123456')));
        },
      );

      test('concurrent setPin calls produce deterministic final PIN', () async {
        final results = await Future.wait([
          service.setPin('1111'),
          service.setPin('2222'),
          service.setPin('3333'),
        ]);

        final successCount = results.whereType<Success<void>>().length;
        expect(successCount, 1);
        final salt = await storage.read(key: 'pin_salt');
        expect(salt, isNotNull);
        expect(salt, isNotEmpty);
        final hash = await storage.read(key: 'pin_hash');
        expect(hash, isNotNull);
        expect(hash, isNotEmpty);

        final candidates = ['1111', '2222', '3333'];
        final matchingCandidates = candidates
            .where((pin) => _expectedHash(pin, salt!) == hash)
            .toList();
        expect(matchingCandidates.length, 1);
        expect(
          await service.authenticatePin(matchingCandidates.single),
          isTrue,
        );
        for (final other in candidates.where(
          (p) => p != matchingCandidates.single,
        )) {
          expect(await service.authenticatePin(other), isFalse);
        }
      });

      test('returns UnknownFailure when storage write fails', () async {
        final exception = Exception('secure storage write failed');
        service = SecurePinAuthService(
          storage: _ThrowingWriteStorage(exception),
        );

        final result = await service.setPin('1234');

        expect(result, isA<Err<void>>());
        final failure = (result as Err<void>).failure as UnknownFailure;
        expect(failure.message, 'Failed to store PIN.');
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

      test('returns false for short PIN when none is set', () async {
        final authenticated = await service.authenticatePin('12');

        expect(authenticated, isFalse);
        expect(await service.isPinSet(), isFalse);
      });

      test('uses salt to produce different hashes for the same PIN', () async {
        final storageA = _FakeSecureStorage();
        final storageB = _FakeSecureStorage();
        final serviceA = SecurePinAuthService(storage: storageA);
        final serviceB = SecurePinAuthService(storage: storageB);

        await serviceA.setPin('1234');
        await serviceB.setPin('1234');

        final hashA = await storageA.read(key: 'pin_hash');
        final hashB = await storageB.read(key: 'pin_hash');

        expect(hashA, isNot(equals(hashB)));
      });

      test(
        'returns false when stored hash exists but salt is missing',
        () async {
          await service.setPin('1234');
          await storage.delete(key: 'pin_salt');

          expect(await service.authenticatePin('1234'), isFalse);
        },
      );

      test('returns false for PIN with non-digit characters', () async {
        await service.setPin('1234');

        expect(await service.authenticatePin('12a4'), isFalse);
      });

      test('returns false when stored hash exists but salt is empty', () async {
        await service.setPin('1234');
        await storage.write(key: 'pin_salt', value: '');

        expect(await service.authenticatePin('1234'), isFalse);
      });

      test(
        'returns false when storage read throws during authenticate',
        () async {
          await service.setPin('1234');
          service = SecurePinAuthService(
            storage: _ThrowingReadStorage(Exception('read failed')),
          );

          expect(await service.authenticatePin('1234'), isFalse);
        },
      );

      test('returns false when stored hash is corrupted', () async {
        await storage.write(key: 'pin_hash', value: 'not-a-valid-hash');
        await storage.write(key: 'pin_salt', value: 'some-salt');

        expect(await service.authenticatePin('1234'), isFalse);
      });
    });
  });
}
