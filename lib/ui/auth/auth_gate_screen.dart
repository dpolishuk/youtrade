import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failures.dart';
import '../../domain/auth/auth_failure.dart';
import '../../presentation/auth/auth_guard_provider.dart';
import '../../presentation/auth/auth_state.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).checkBiometricAvailability();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return switch (authState) {
      AuthAuthenticated() => widget.child,
      AuthUnknown() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthUnauthenticated() || AuthError() => _buildGate(authState),
    };
  }

  Widget _buildGate(AuthState state) {
    final failure = state is AuthError ? state.failure : null;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'YouTrade is locked',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Authenticate to continue',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(authNotifierProvider.notifier)
                      .authenticateWithBiometrics();
                },
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock with biometrics'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  hintText: 'Enter PIN',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: (_) => _submitPin(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitPin,
                child: const Text('Unlock with PIN'),
              ),
              if (failure != null) ...[
                const SizedBox(height: 16),
                Text(
                  _failureMessage(failure),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _submitPin() {
    final pin = _pinController.text;
    ref.read(authNotifierProvider.notifier).authenticateWithPin(pin);
  }

  String _failureMessage(Failure failure) {
    if (failure is AuthFailure) return failure.message;
    return failure.message;
  }
}
