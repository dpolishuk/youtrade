import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';
import 'settings_section.dart';

class ConnectedExchangesSection extends StatelessWidget {
  const ConnectedExchangesSection({required this.venues, super.key});

  final List<String> venues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return SettingsSection(
      title: 'Connected exchanges',
      children: [
        for (var i = 0; i < venues.length; i++)
          _ExchangeRow(
            name: venues[i],
            isLast: i == venues.length - 1,
            bullish: appColors.bullish,
          ),
      ],
    );
  }
}

class _ExchangeRow extends StatelessWidget {
  const _ExchangeRow({
    required this.name,
    required this.isLast,
    required this.bullish,
  });

  final String name;
  final bool isLast;
  final Color bullish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: appColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: bullish,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: bullish.withValues(alpha: 0.5), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Connected',
            style: theme.textTheme.labelSmall?.copyWith(
              color: bullish,
              letterSpacing: 0.05 * 9,
            ),
          ),
        ],
      ),
    );
  }
}
