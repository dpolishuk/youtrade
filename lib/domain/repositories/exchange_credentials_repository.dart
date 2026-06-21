import '../../core/result.dart';
import '../auth/exchange_credentials.dart';
import '../entities/venue.dart';

abstract interface class ExchangeCredentialsRepository {
  Future<Result<void>> save(ExchangeCredentials credentials);

  Future<Result<ExchangeCredentials?>> load(Venue venue);

  Future<Result<void>> delete(Venue venue);

  Future<Result<List<ExchangeCredentials>>> list();

  Future<Result<bool>> testConnection(ExchangeCredentials credentials);
}
