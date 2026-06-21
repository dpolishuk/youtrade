import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/secure_credentials_store.dart';
import '../../data/datasources/remote/exchange_connection_checker_impl.dart';
import '../../data/repositories/exchange_credentials_repository_impl.dart';
import '../../domain/auth/exchange_connection_checker.dart';
import '../../domain/repositories/exchange_credentials_repository.dart';
import 'exchange_credentials_notifier.dart';
import 'exchange_credentials_state.dart';

final secureCredentialsStoreProvider = Provider<SecureCredentialsStore>((ref) {
  return SecureCredentialsStoreImpl();
});

final exchangeConnectionCheckerProvider = Provider<ExchangeConnectionChecker>((
  ref,
) {
  return ExchangeConnectionCheckerImpl();
});

final exchangeCredentialsRepositoryProvider =
    Provider<ExchangeCredentialsRepository>((ref) {
      final store = ref.watch(secureCredentialsStoreProvider);
      final checker = ref.watch(exchangeConnectionCheckerProvider);

      return ExchangeCredentialsRepositoryImpl(
        store: store,
        connectionChecker: checker,
      );
    });

final exchangeCredentialsNotifierProvider =
    StateNotifierProvider<
      ExchangeCredentialsNotifier,
      ExchangeCredentialsState
    >((ref) {
      final repository = ref.watch(exchangeCredentialsRepositoryProvider);
      return ExchangeCredentialsNotifier(repository);
    });
