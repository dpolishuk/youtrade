import '../../../core/failures.dart';
import '../../../domain/auth/exchange_credentials.dart';

sealed class ExchangeCredentialsState {
  const ExchangeCredentialsState();
}

final class ExchangeCredentialsLoading extends ExchangeCredentialsState {
  const ExchangeCredentialsLoading();
}

final class ExchangeCredentialsLoaded extends ExchangeCredentialsState {
  const ExchangeCredentialsLoaded(this.credentials);

  final List<ExchangeCredentials> credentials;
}

final class ExchangeCredentialsError extends ExchangeCredentialsState {
  const ExchangeCredentialsError(this.failure);

  final Failure failure;
}

final class ExchangeCredentialsTesting extends ExchangeCredentialsState {
  const ExchangeCredentialsTesting(this.venue);

  final String venue;
}

final class ExchangeCredentialsTestSuccess extends ExchangeCredentialsState {
  const ExchangeCredentialsTestSuccess(this.venue);

  final String venue;
}

final class ExchangeCredentialsTestFailure extends ExchangeCredentialsState {
  const ExchangeCredentialsTestFailure(this.venue, this.failure);

  final String venue;
  final Failure failure;
}
