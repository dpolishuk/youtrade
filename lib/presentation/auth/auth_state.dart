import '../../core/failures.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.pinSet = true});

  final bool pinSet;
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

final class AuthError extends AuthState {
  const AuthError(this.failure);

  final Failure failure;
}
