import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth/auth_failure.dart';
import '../../domain/auth/local_auth_service.dart';
import '../../domain/auth/pin_auth_service.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._localAuthService, this._pinAuthService)
    : super(const AuthUnknown());

  static final _pinRegex = RegExp(r'^\d{4}$');

  final LocalAuthService _localAuthService;
  final PinAuthService _pinAuthService;

  bool _pinSet = false;
  bool _isBiometricAvailable = false;
  bool _isAuthenticating = false;
  bool _isInitializing = false;
  int _failedPinAttempts = 0;
  DateTime? _pinLockoutEnd;

  static const int _maxPinAttempts = 5;
  static const Duration _pinLockoutDuration = Duration(minutes: 15);

  bool get isPinSet => _pinSet;

  bool get isBiometricAvailable => _isBiometricAvailable;

  bool get isAuthenticating => _isAuthenticating;

  static const Duration _initTimeout = Duration(seconds: 3);

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      _pinSet = await _pinAuthService.isPinSet().timeout(
        _initTimeout,
        onTimeout: () => false,
      );

      if (!_pinSet) {
        _isBiometricAvailable = false;
        state = const AuthUnauthenticated(pinSet: false);
        return;
      }

      try {
        _isBiometricAvailable = await _localAuthService
            .canCheckBiometrics()
            .timeout(_initTimeout, onTimeout: () => false);
      } on Object {
        _isBiometricAvailable = false;
        state = const AuthUnauthenticated(pinSet: true);
        return;
      }

      state = const AuthUnauthenticated(pinSet: true);
    } on Object {
      _pinSet = false;
      _isBiometricAvailable = false;
      state = const AuthUnauthenticated(pinSet: false);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    try {
      _pinSet = await _pinAuthService.isPinSet();
      final result = await _localAuthService.authenticate();
      if (!_isAuthenticating) return;
      result.when(
        success: (_) {
          _resetPinLockout();
          state = const AuthAuthenticated();
        },
        failure: (failure) => state = AuthError(failure),
      );
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<void> authenticateWithPin(String pin) async {
    if (_isAuthenticating) return;

    final lockoutRemaining = _lockoutRemainingSeconds;
    if (lockoutRemaining > 0) {
      state = AuthError(PinLockedFailure(lockoutRemaining));
      return;
    }

    _isAuthenticating = true;
    try {
      _pinSet = await _pinAuthService.isPinSet();

      if (!_pinRegex.hasMatch(pin)) {
        if (_isAuthenticating) {
          state = const AuthError(
            PinValidationFailure('PIN must be exactly 4 digits'),
          );
        }
        return;
      }

      if (!_pinSet) {
        final result = await _pinAuthService.setPin(pin);
        if (!_isAuthenticating) return;
        result.when(
          success: (_) {
            _pinSet = true;
            _resetPinLockout();
            state = const AuthAuthenticated();
          },
          failure: (failure) => state = AuthError(failure),
        );
        return;
      }

      final isValid = await _pinAuthService.authenticatePin(pin);
      if (!_isAuthenticating) return;
      if (isValid) {
        _resetPinLockout();
        state = const AuthAuthenticated();
      } else {
        _recordFailedPinAttempt();
        state = const AuthError(PinMismatchFailure());
      }
    } finally {
      _isAuthenticating = false;
    }
  }

  void signOut() {
    _isAuthenticating = false;
    if (state is AuthUnauthenticated &&
        (state as AuthUnauthenticated).pinSet == _pinSet) {
      return;
    }
    state = AuthUnauthenticated(pinSet: _pinSet);
  }

  int get _lockoutRemainingSeconds {
    final end = _pinLockoutEnd;
    if (end == null) return 0;
    final remaining = end.difference(DateTime.now().toUtc()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  void _recordFailedPinAttempt() {
    _failedPinAttempts++;
    if (_failedPinAttempts >= _maxPinAttempts) {
      _pinLockoutEnd = DateTime.now().toUtc().add(_pinLockoutDuration);
    }
  }

  void _resetPinLockout() {
    _failedPinAttempts = 0;
    _pinLockoutEnd = null;
  }
}
