import '../../core/failures.dart';

sealed class AuthFailure implements Failure {
  const AuthFailure();
}

final class BiometricNotAvailableFailure extends AuthFailure {
  const BiometricNotAvailableFailure();

  @override
  String get message =>
      'Biometric authentication is not available on this device.';

  @override
  bool operator ==(Object other) => other is BiometricNotAvailableFailure;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class AuthCancelledFailure extends AuthFailure {
  const AuthCancelledFailure();

  @override
  String get message => 'Authentication was cancelled.';

  @override
  bool operator ==(Object other) => other is AuthCancelledFailure;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class AuthFailedFailure extends AuthFailure {
  const AuthFailedFailure();

  @override
  String get message => 'Authentication failed. Please try again.';

  @override
  bool operator ==(Object other) => other is AuthFailedFailure;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class PinNotSetFailure extends AuthFailure {
  const PinNotSetFailure();

  @override
  String get message => 'PIN authentication is not set up.';

  @override
  bool operator ==(Object other) => other is PinNotSetFailure;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class PinMismatchFailure extends AuthFailure {
  const PinMismatchFailure();

  @override
  String get message => 'Incorrect PIN. Please try again.';

  @override
  bool operator ==(Object other) => other is PinMismatchFailure;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class PinValidationFailure extends AuthFailure {
  const PinValidationFailure(this.message);

  @override
  final String message;

  @override
  bool operator ==(Object other) =>
      other is PinValidationFailure && other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class PinLockedFailure extends AuthFailure {
  const PinLockedFailure(this.remainingSeconds);

  final int remainingSeconds;

  @override
  String get message =>
      'Too many failed attempts. Try again in $remainingSeconds seconds.';

  @override
  bool operator ==(Object other) =>
      other is PinLockedFailure && other.remainingSeconds == remainingSeconds;

  @override
  int get hashCode => Object.hash(runtimeType, remainingSeconds);
}
