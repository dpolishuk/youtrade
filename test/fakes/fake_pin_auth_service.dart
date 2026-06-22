import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/pin_auth_service.dart';

class FakePinAuthService implements PinAuthService {
  FakePinAuthService({
    String? initialPin,
    this.failureOnSet,
    this.exceptionOnIsPinSet,
  }) : _pin = initialPin;

  String? _pin;
  final Failure? failureOnSet;
  final Exception? exceptionOnIsPinSet;

  @override
  Future<bool> isPinSet() async {
    final exception = exceptionOnIsPinSet;
    if (exception != null) throw exception;
    return _pin != null;
  }

  @override
  Future<bool> authenticatePin(String pin) async {
    if (pin.length < 4) return false;
    if (_pin == null) {
      _pin = pin;
      return true;
    }
    return pin == _pin;
  }

  @override
  Future<Result<void>> setPin(String pin) async {
    if (failureOnSet != null) {
      return Err<void>(failureOnSet!);
    }
    _pin = pin;
    return const Success<void>(null);
  }

  void setStoredPin(String pin) {
    _pin = pin;
  }

  void clearStoredPin() {
    _pin = null;
  }
}
