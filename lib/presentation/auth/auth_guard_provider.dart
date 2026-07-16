import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/local_auth_service_impl.dart';
import '../../data/auth/secure_pin_auth_service.dart';
import '../../domain/auth/local_auth_service.dart';
import '../../domain/auth/pin_auth_service.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

final localAuthServiceProvider = Provider<LocalAuthService>((ref) {
  return LocalAuthServiceImpl();
});

final pinAuthServiceProvider = Provider<PinAuthService>((ref) {
  return SecurePinAuthService();
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final localAuthService = ref.watch(localAuthServiceProvider);
  final pinAuthService = ref.watch(pinAuthServiceProvider);
  return AuthNotifier(localAuthService, pinAuthService);
});
