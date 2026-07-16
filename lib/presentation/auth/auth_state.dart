import '../../core/failures.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthUnknown extends AuthState {
  const AuthUnknown();

  @override
  bool operator ==(Object other) => other is AuthUnknown;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.pinSet = true});

  final bool pinSet;

  @override
  bool operator ==(Object other) =>
      other is AuthUnauthenticated && other.pinSet == pinSet;

  @override
  int get hashCode => Object.hash(runtimeType, pinSet);
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();

  @override
  bool operator ==(Object other) => other is AuthAuthenticated;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class AuthError extends AuthState {
  const AuthError(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is AuthError && other.failure == failure;

  @override
  int get hashCode => Object.hash(runtimeType, failure);
}
