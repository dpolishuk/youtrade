import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/pin_auth_service.dart';

class RaceyFakePinAuthService implements PinAuthService {
  RaceyFakePinAuthService();

  int _setPinCalls = 0;
  String? _pin;

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

  void setStoredPin(String pin) {
    _pin = pin;
  }
}
