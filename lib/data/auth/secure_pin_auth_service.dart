import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/auth/auth_failure.dart';
import '../../domain/auth/pin_auth_service.dart';

class SecurePinAuthService implements PinAuthService {
  SecurePinAuthService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const String _failedPinAttemptsKey = 'failed_pin_attempts';
  static const String _pinLockoutEndKey = 'pin_lockout_end';
  static const int _pinLength = 4;
  static const int pbkdf2Iterations = 600000;
  static const int _derivedKeyLength = 32;
  static final RegExp _pinRegex = RegExp(r'^\d{4}$');

  @override
  Future<bool> isPinSet() async {
    try {
      final hash = await _storage.read(key: _pinHashKey);
      return hash != null && hash.isNotEmpty;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticatePin(String pin) async {
    if (pin.length != _pinLength || !_pinRegex.hasMatch(pin)) return false;

    try {
      final storedHash = await _storage.read(key: _pinHashKey);
      if (storedHash == null) {
        final result = await setPin(pin);
        return result is Success<void>;
      }

      final salt = await _storage.read(key: _pinSaltKey) ?? '';
      final hash = _hashPin(pin, salt);
      return hash == storedHash;
    } on Object {
      return false;
    }
  }

  Future<Result<void>>? _setPinLock;

  @override
  Future<Result<void>> setPin(String pin) async {
    if (pin.length != _pinLength) {
      return const Err<void>(
        PinValidationFailure('PIN must be exactly 4 digits.'),
      );
    }

    if (!_pinRegex.hasMatch(pin)) {
      return const Err<void>(
        PinValidationFailure('PIN must contain only digits.'),
      );
    }

    if (_setPinLock != null) {
      return const Err<void>(UnknownFailure('PIN setup already in progress.'));
    }

    final operation = _setPinInternal(pin);
    _setPinLock = operation;
    try {
      return await operation;
    } finally {
      _setPinLock = null;
    }
  }

  Future<Result<void>> _setPinInternal(String pin) async {
    try {
      var salt = await _storage.read(key: _pinSaltKey);
      if (salt == null || salt.isEmpty) {
        salt = _generateSalt();
        await _storage.write(key: _pinSaltKey, value: salt);
      }

      final hash = _hashPin(pin, salt);
      await _storage.write(key: _pinHashKey, value: hash);
      await _storage.write(key: _failedPinAttemptsKey, value: '0');
      await _storage.delete(key: _pinLockoutEndKey);
      return const Success<void>(null);
    } on Object catch (e) {
      return Err<void>(UnknownFailure('Failed to store PIN.', error: e));
    }
  }

  @override
  Future<int> getFailedPinAttempts() async {
    try {
      final value = await _storage.read(key: _failedPinAttemptsKey);
      if (value == null || value.isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    } on Object {
      return 0;
    }
  }

  @override
  Future<void> setFailedPinAttempts(int attempts) async {
    try {
      await _storage.write(
        key: _failedPinAttemptsKey,
        value: attempts.toString(),
      );
    } on Object {
      // Ignore storage write failures for lockout metadata.
    }
  }

  @override
  Future<DateTime?> getPinLockoutEnd() async {
    try {
      final value = await _storage.read(key: _pinLockoutEndKey);
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value)?.toUtc();
    } on Object {
      return null;
    }
  }

  @override
  Future<void> setPinLockoutEnd(DateTime? end) async {
    try {
      if (end == null) {
        await _storage.delete(key: _pinLockoutEndKey);
      } else {
        await _storage.write(
          key: _pinLockoutEndKey,
          value: end.toUtc().toIso8601String(),
        );
      }
    } on Object {
      // Ignore storage write failures for lockout metadata.
    }
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final saltBytes = base64Decode(salt);
    final pinBytes = Uint8List.fromList(utf8.encode(pin));
    final params = Pbkdf2Parameters(
      Uint8List.fromList(saltBytes),
      pbkdf2Iterations,
      _derivedKeyLength,
    );
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(params);
    final key = pbkdf2.process(pinBytes);
    return _bytesToHex(key);
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
