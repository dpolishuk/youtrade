import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../../core/result.dart';
import '../../domain/auth/auth_failure.dart';
import '../../domain/auth/local_auth_service.dart';

class LocalAuthServiceImpl implements LocalAuthService {
  LocalAuthServiceImpl({LocalAuthentication? localAuthentication})
    : _localAuth = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  @override
  Future<bool> canCheckBiometrics() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      final deviceSupported = await _localAuth.isDeviceSupported();
      return available && deviceSupported;
    } on Object {
      return false;
    }
  }

  @override
  Future<Result<bool>> authenticate() async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access YouTrade',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Biometric authentication required',
            cancelButton: 'Use PIN',
            biometricHint: 'Verify your identity',
            biometricNotRecognized: 'Not recognized, try again',
            biometricRequiredTitle: 'Biometric authentication is required',
            deviceCredentialsRequiredTitle: 'Device credentials required',
            deviceCredentialsSetupDescription:
                'Please set up device credentials',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription:
                'Please set up biometric authentication in Settings',
          ),
          IOSAuthMessages(
            cancelButton: 'Use PIN',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription:
                'Please set up biometric authentication in Settings',
            lockOut: 'Please reenable biometric authentication',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: false,
        ),
      );

      if (didAuthenticate) {
        return const Success(true);
      }

      return const Err(AuthCancelledFailure());
    } on PlatformException catch (e) {
      return Err(_mapPlatformException(e));
    } on Object {
      return const Err(AuthFailedFailure());
    }
  }

  AuthFailure _mapPlatformException(PlatformException exception) {
    late final String? code;
    try {
      code = exception.code;
    } on TypeError catch (_) {
      code = null;
    }
    return switch (code) {
      auth_error.notAvailable ||
      auth_error.notEnrolled ||
      auth_error.passcodeNotSet => const BiometricNotAvailableFailure(),
      auth_error.lockedOut ||
      auth_error.permanentlyLockedOut => const AuthFailedFailure(),
      _ => const AuthCancelledFailure(),
    };
  }
}
