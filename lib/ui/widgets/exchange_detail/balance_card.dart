import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final labelColor =
        appColors?.tertiaryText ?? theme.colorScheme.onSurfaceVariant;
    final valueColor = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: appColors?.borderSubtle ?? theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: labelColor,
              letterSpacing: 0.07 * 9,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w600,
                letterSpacing: -0.03 * 24,
                fontSize: 24,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
