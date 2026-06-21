import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../domain/auth/exchange_connection_checker.dart';
import '../../../domain/auth/exchange_credentials.dart';
import '../../../domain/entities/venue.dart';
import '../../../domain/repositories/exchange_credentials_repository.dart';
import '../datasources/local/secure_credentials_store.dart';

final class ExchangeCredentialsRepositoryImpl
    implements ExchangeCredentialsRepository {
  ExchangeCredentialsRepositoryImpl({
    required SecureCredentialsStore store,
    required ExchangeConnectionChecker connectionChecker,
  }) : _store = store,
       _connectionChecker = connectionChecker;

  final SecureCredentialsStore _store;
  final ExchangeConnectionChecker _connectionChecker;

  @override
  Future<Result<void>> save(ExchangeCredentials credentials) async {
    try {
      await _store.save(credentials);
      return const Success(null);
    } on Exception catch (e) {
      return Err(UnknownFailure('Failed to save credentials', error: e));
    }
  }

  @override
  Future<Result<ExchangeCredentials?>> load(Venue venue) async {
    try {
      final credentials = await _store.load(venue);
      return Success(credentials);
    } on Exception catch (e) {
      return Err(UnknownFailure('Failed to load credentials', error: e));
    }
  }

  @override
  Future<Result<void>> delete(Venue venue) async {
    try {
      await _store.delete(venue);
      return const Success(null);
    } on Exception catch (e) {
      return Err(UnknownFailure('Failed to delete credentials', error: e));
    }
  }

  @override
  Future<Result<List<ExchangeCredentials>>> list() async {
    try {
      final credentials = await _store.loadAll();
      return Success(credentials);
    } on Exception catch (e) {
      return Err(UnknownFailure('Failed to list credentials', error: e));
    }
  }

  @override
  Future<Result<bool>> testConnection(ExchangeCredentials credentials) async {
    if (credentials.apiKey.isEmpty || credentials.secret.isEmpty) {
      return const Err(ValidationFailure('API key and secret are required'));
    }

    return _connectionChecker.check(credentials);
  }
}

final class ValidationFailure extends Failure {
  const ValidationFailure(this.message);

  @override
  final String message;
}
