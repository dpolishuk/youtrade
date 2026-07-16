import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class ExpirySelector extends StatelessWidget {
  const ExpirySelector({
    required this.expiries,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<String> expiries;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            for (var i = 0; i < expiries.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _ExpiryPill(
                  label: expiries[i],
                  isSelected: i == selectedIndex,
                  appColors: appColors,
                  theme: theme,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryPill extends StatelessWidget {
  const _ExpiryPill({
    required this.label,
    required this.isSelected,
    required this.appColors,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final AppColorTheme appColors;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : appColors.chip;
    final fg = isSelected ? theme.colorScheme.primary : appColors.subtleText;
    final border = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.4)
        : appColors.borderSubtle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontFamily: 'JetBrains Mono',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
