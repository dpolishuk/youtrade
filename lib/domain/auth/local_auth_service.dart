import '../../core/result.dart';

abstract interface class LocalAuthService {
  Future<Result<bool>> authenticate();

  Future<bool> canCheckBiometrics();
}
