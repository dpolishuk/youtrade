import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/flutter_secure_storage_key_value_storage.dart';
import '../../data/auth/local_auth_service_impl.dart';
import '../../data/auth/secure_pin_auth_service.dart';
import '../../domain/auth/local_auth_service.dart';
import '../../domain/auth/pin_auth_service.dart';
import '../../domain/auth/secure_key_value_storage.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

final localAuthServiceProvider = Provider<LocalAuthService>((ref) {
  return LocalAuthServiceImpl();
});

/// Platform-backed secure store (Keychain/Keystore with a SharedPreferences
/// fallback for unsigned simulator builds). Override in tests with an
/// [InMemorySecureKeyValueStorage].
final secureKeyValueStorageProvider = Provider<SecureKeyValueStorage>((ref) {
  return FlutterSecureStorageKeyValueStorage();
});

final pinAuthServiceProvider = Provider<PinAuthService>((ref) {
  return SecurePinAuthService(
    storage: ref.watch(secureKeyValueStorageProvider),
  );
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final localAuthService = ref.watch(localAuthServiceProvider);
  final pinAuthService = ref.watch(pinAuthServiceProvider);
  return AuthNotifier(localAuthService, pinAuthService);
});
