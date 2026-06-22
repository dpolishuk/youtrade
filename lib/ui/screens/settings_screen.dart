import 'package:flutter/material.dart';

import '../../presentation/theme/theme_extensions.dart';
import '../widgets/settings/connected_exchanges_section.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/theme_toggle.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<String> _connectedVenues = [
    'Binance',
    'Bybit',
    'OKX',
    'Coinbase',
  ];

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;

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
              const ConnectedExchangesSection(venues: _connectedVenues),
              const SizedBox(height: 18),
              const SettingsSection(
                title: 'Appearance',
                children: [ThemeToggle(), VisualDirectionToggle()],
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'YouTrade · v1.0 · ${_connectedVenues.length} venues linked',
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
