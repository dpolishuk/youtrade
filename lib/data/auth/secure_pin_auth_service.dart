import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  static const int _minPinLength = 4;
  static final RegExp _pinRegex = RegExp(r'^\d+$');

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
    if (pin.length < _minPinLength) return false;

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
    if (pin.length < _minPinLength) {
      return const Err<void>(
        PinValidationFailure('PIN must be at least 4 digits.'),
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
      return const Success<void>(null);
    } on Object catch (e) {
      return Err<void>(UnknownFailure('Failed to store PIN.', error: e));
    }
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt$pin');
    return sha256.convert(bytes).toString();
  }
}
