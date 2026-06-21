import 'package:flutter/material.dart';

import '../../presentation/theme/theme_extensions.dart';
import '../widgets/settings/connected_exchanges_section.dart';
import '../widgets/settings/security_section.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/theme_toggle.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<String> _connectedVenues = [
    'Binance',
    'Bybit',
    'Coinbase',
    'Kraken',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

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
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.02 * 18,
                ),
              ),
              const SizedBox(height: 18),
              const ConnectedExchangesSection(venues: _connectedVenues),
              const SizedBox(height: 18),
              const SettingsSection(
                title: 'Appearance',
                children: [ThemeToggle(), VisualDirectionToggle()],
              ),
              const SizedBox(height: 18),
              const SecuritySection(),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'YouTrade · v1.0 · ${_connectedVenues.length} venues linked',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: appColors.subtleText,
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
