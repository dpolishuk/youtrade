import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/auth/auth_guard_provider.dart';
import '../../presentation/auth/auth_state.dart';
import '../../presentation/theme/theme_extensions.dart';
import '../widgets/settings/connected_exchanges_section.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_tile.dart';
import '../widgets/settings/theme_toggle.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const List<String> _connectedVenues = [
    'Binance',
    'Bybit',
    'OKX',
    'Coinbase',
  ];

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final authState = ref.watch(authNotifierProvider);
    final notifier = ref.read(authNotifierProvider.notifier);
    final pinSet = notifier.isPinSet;
    final biometricsAvailable = notifier.isBiometricAvailable;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Account',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.02 * 18,
                  color: appColors.foreground,
                ),
              ),
              const SizedBox(height: 14),
              const ConnectedExchangesSection(
                venues: SettingsScreen._connectedVenues,
              ),
              const SizedBox(height: 18),
              if (authState is AuthUnauthenticated ||
                  authState is AuthAuthenticated)
                _SecuritySection(
                  pinSet: pinSet,
                  biometricsAvailable: biometricsAvailable,
                ),
              if (authState is AuthUnauthenticated ||
                  authState is AuthAuthenticated)
                const SizedBox(height: 18),
              const SettingsSection(
                title: 'Appearance',
                children: [ThemeToggle(), VisualDirectionToggle()],
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'YouTrade · v1.0 · ${SettingsScreen._connectedVenues.length} venues linked',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    color: appColors.tertiaryText,
                    letterSpacing: 0.06 * 9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecuritySection extends StatelessWidget {
  const _SecuritySection({
    required this.pinSet,
    required this.biometricsAvailable,
  });

  final bool pinSet;
  final bool biometricsAvailable;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;

    return SettingsSection(
      title: 'Protection',
      children: [
        if (!pinSet)
          SettingsTile(
            title: 'Set up PIN',
            trailing: Icon(
              Icons.chevron_right,
              size: 18,
              color: appColors.tertiaryText,
            ),
          )
        else if (biometricsAvailable)
          SettingsTile(
            title: 'Unlock with biometrics',
            trailing: Icon(
              Icons.fingerprint,
              size: 18,
              color: appColors.accent,
            ),
          )
        else
          SettingsTile(
            title: 'PIN enabled',
            trailing: Icon(Icons.check, size: 18, color: appColors.bullish),
          ),
      ],
    );
  }
}
