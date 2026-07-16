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
          title.toUpperCase(),
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1 * 9,
            color: appColors.tertiaryText,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border.all(color: appColors.line),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
