import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: appColors.subtleText,
            letterSpacing: 0.1 * 9,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: appColors.borderSubtle),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
