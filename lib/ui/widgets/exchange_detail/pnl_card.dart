import 'package:flutter/material.dart';

class PnlCard extends StatelessWidget {
  const PnlCard({
    required this.label,
    required this.value,
    required this.percent,
    required this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final String percent;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
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
          const SizedBox(height: 2),
          Text(
            percent,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'Geist Mono',
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
