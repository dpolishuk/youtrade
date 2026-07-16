import '../../core/result.dart';

abstract interface class PinAuthService {
  Future<bool> isPinSet();

  Future<bool> authenticatePin(String pin);

  Future<Result<void>> setPin(String pin);

  Future<int> getFailedPinAttempts();

  Future<void> setFailedPinAttempts(int attempts);

  Future<DateTime?> getPinLockoutEnd();

  Future<void> setPinLockoutEnd(DateTime? end);
}
