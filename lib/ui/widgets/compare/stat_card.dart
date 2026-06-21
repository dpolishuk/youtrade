import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

/// Compact stat display used for correlation and ratio metrics.
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColorTheme>()!;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: appColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.07 * 9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'Geist Mono',
                fontWeight: FontWeight.w600,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
