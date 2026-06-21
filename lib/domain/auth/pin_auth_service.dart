import '../../core/result.dart';

abstract interface class PinAuthService {
  Future<bool> isPinSet();

  Future<bool> authenticatePin(String pin);

  Future<Result<void>> setPin(String pin);
}
