import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/auth/auth_guard_provider.dart';
import '../../../presentation/auth/auth_notifier.dart';
import 'settings_section.dart';
import 'settings_tile.dart';

class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: 'Security',
      children: [
        SettingsTile(
          title: 'Biometric / PIN',
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => _onBiometricPinTapped(
            context,
            ref.read(authNotifierProvider.notifier),
          ),
        ),
        SettingsTile(
          title: 'Sign out',
          isLast: true,
          onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
        ),
      ],
    );
  }

  void _onBiometricPinTapped(BuildContext context, AuthNotifier notifier) {
    notifier.initialize();
  }
}
