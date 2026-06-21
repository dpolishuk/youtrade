import '../../core/failures.dart';

sealed class AuthFailure implements Failure {
  const AuthFailure();
}

final class BiometricNotAvailableFailure extends AuthFailure {
  const BiometricNotAvailableFailure();

  @override
  String get message =>
      'Biometric authentication is not available on this device.';
}

final class AuthCancelledFailure extends AuthFailure {
  const AuthCancelledFailure();

  @override
  String get message => 'Authentication was cancelled.';
}

final class AuthFailedFailure extends AuthFailure {
  const AuthFailedFailure();

  @override
  String get message => 'Authentication failed. Please try again.';
}

final class PinNotSetFailure extends AuthFailure {
  const PinNotSetFailure();

  @override
  String get message => 'PIN authentication is not set up.';
}

final class PinMismatchFailure extends AuthFailure {
  const PinMismatchFailure();

  @override
  String get message => 'Incorrect PIN. Please try again.';
}
