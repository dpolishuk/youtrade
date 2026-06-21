import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth/auth_failure.dart';
import '../../domain/auth/local_auth_service.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._localAuthService) : super(const AuthUnknown());

  final LocalAuthService _localAuthService;

  static const String _demoPin = '1234';

  Future<void> checkBiometricAvailability() async {
    final canCheck = await _localAuthService.canCheckBiometrics();
    if (canCheck) {
      await authenticateWithBiometrics();
    } else {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> authenticateWithBiometrics() async {
    final result = await _localAuthService.authenticate();
    result.when(
      success: (_) => state = const AuthAuthenticated(),
      failure: (failure) => state = AuthError(failure),
    );
  }

  Future<void> authenticateWithPin(String pin) async {
    if (pin.isEmpty) {
      state = const AuthError(PinMismatchFailure());
      return;
    }

    if (pin == _demoPin) {
      state = const AuthAuthenticated();
    } else {
      state = const AuthError(PinMismatchFailure());
    }
  }

  void signOut() {
    state = const AuthUnauthenticated();
  }
}
