import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/pin_auth_service.dart';

class FakePinAuthService implements PinAuthService {
  FakePinAuthService({
    String? initialPin,
    this.failureOnSet,
    this.exceptionOnIsPinSet,
    this.exceptionOnSet,
    this.exceptionOnAuthenticatePin,
    int initialFailedAttempts = 0,
    DateTime? initialPinLockoutEnd,
  }) : _pin = initialPin,
       _failedPinAttempts = initialFailedAttempts,
       _pinLockoutEnd = initialPinLockoutEnd;

  String? _pin;
  int _failedPinAttempts;
  DateTime? _pinLockoutEnd;
  final Failure? failureOnSet;
  final Exception? exceptionOnIsPinSet;
  final Exception? exceptionOnSet;
  final Exception? exceptionOnAuthenticatePin;

  @override
  Future<bool> isPinSet() async {
    final exception = exceptionOnIsPinSet;
    if (exception != null) throw exception;
    return _pin != null;
  }

  @override
  Future<bool> authenticatePin(String pin) async {
    final exception = exceptionOnAuthenticatePin;
    if (exception != null) throw exception;
    if (pin.length != 4) return false;
    if (_pin == null) {
      _pin = pin;
      return true;
    }
    return pin == _pin;
  }

  @override
  Future<Result<void>> setPin(String pin) async {
    final exception = exceptionOnSet;
    if (exception != null) throw exception;
    if (failureOnSet != null) {
      return Err<void>(failureOnSet!);
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

  void setStoredPin(String pin) {
    _pin = pin;
  }

  void clearStoredPin() {
    _pin = null;
  }
}
