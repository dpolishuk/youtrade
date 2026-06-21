import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class GreekBadge extends StatelessWidget {
  const GreekBadge({
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: backgroundColor ?? appColors.surfaceGlass,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06 * 8,
          color: foregroundColor ?? appColors.subtleText,
        ),
      ),
    );
  }
}
