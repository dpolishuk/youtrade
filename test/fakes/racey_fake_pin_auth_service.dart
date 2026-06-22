import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/pin_auth_service.dart';

class RaceyFakePinAuthService implements PinAuthService {
  RaceyFakePinAuthService();

  int _setPinCalls = 0;
  String? _pin;
  int _failedPinAttempts = 0;
  DateTime? _pinLockoutEnd;

  @override
  Future<bool> isPinSet() async => _pin != null;

  @override
  Future<bool> authenticatePin(String pin) async => pin == _pin;

  @override
  Future<Result<void>> setPin(String pin) async {
    _setPinCalls++;
    if (_setPinCalls > 1) {
      return const Err<void>(
        UnknownFailure('PIN already set during concurrent race'),
      );
    }
    _pin = pin;
    return const Success<void>(null);
  }

  @override
  Future<int> getFailedPinAttempts() async => _failedPinAttempts;

  @override
  Future<void> setFailedPinAttempts(int attempts) async {
    _failedPinAttempts = attempts;
  }

  @override
  Future<DateTime?> getPinLockoutEnd() async => _pinLockoutEnd;

  @override
  Future<void> setPinLockoutEnd(DateTime? end) async {
    _pinLockoutEnd = end;
  }

  int get setPinCallCount => _setPinCalls;

  void setStoredPin(String pin) {
    _pin = pin;
  }
}
