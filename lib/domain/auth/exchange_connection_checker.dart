import '../../core/result.dart';
import '../auth/exchange_credentials.dart';

abstract interface class ExchangeConnectionChecker {
  Future<Result<bool>> check(ExchangeCredentials credentials);
}
