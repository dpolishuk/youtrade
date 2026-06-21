import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/auth/exchange_credentials.dart';
import '../../../domain/entities/venue.dart';
import '../../../domain/repositories/exchange_credentials_repository.dart';
import 'exchange_credentials_state.dart';

class ExchangeCredentialsNotifier
    extends StateNotifier<ExchangeCredentialsState> {
  ExchangeCredentialsNotifier(this._repository)
    : _credentials = [],
      super(const ExchangeCredentialsLoading());

  final ExchangeCredentialsRepository _repository;
  List<ExchangeCredentials> _credentials;

  List<ExchangeCredentials> get credentials => List.unmodifiable(_credentials);

  Future<void> loadAll() async {
    state = const ExchangeCredentialsLoading();
    final result = await _repository.list();
    result.when(
      success: (credentials) {
        _credentials = credentials;
        state = ExchangeCredentialsLoaded(credentials);
      },
      failure: (failure) => state = ExchangeCredentialsError(failure),
    );
  }

  Future<void> save(ExchangeCredentials credentials) async {
    final result = await _repository.save(credentials);
    result.when(
      success: (_) => loadAll(),
      failure: (failure) => state = ExchangeCredentialsError(failure),
    );
  }

  Future<void> delete(Venue venue) async {
    final result = await _repository.delete(venue);
    result.when(
      success: (_) => loadAll(),
      failure: (failure) => state = ExchangeCredentialsError(failure),
    );
  }

  Future<void> testConnection(ExchangeCredentials credentials) async {
    state = ExchangeCredentialsTesting(credentials.venue.displayName);
    final result = await _repository.testConnection(credentials);
    result.when(
      success: (_) {
        state = ExchangeCredentialsTestSuccess(credentials.venue.displayName);
      },
      failure: (failure) {
        state = ExchangeCredentialsTestFailure(
          credentials.venue.displayName,
          failure,
        );
      },
    );
  }

  void clearTestResult() {
    final current = state;
    if (current is ExchangeCredentialsLoaded) {
      state = ExchangeCredentialsLoaded(current.credentials);
    } else if (current is! ExchangeCredentialsLoading) {
      state = const ExchangeCredentialsLoading();
      loadAll();
    }
  }
}
