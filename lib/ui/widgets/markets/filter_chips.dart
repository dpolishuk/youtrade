import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/market_screener_provider.dart';
import '../../../presentation/theme/theme_extensions.dart';

class FilterChips extends ConsumerWidget {
  const FilterChips({super.key});

  static const _filters = <(String label, MarketCategory? category)>[
    ('All', null),
    ('Crypto', MarketCategory.crypto),
    ('Stocks', MarketCategory.stocks),
    ('Futures', MarketCategory.futures),
    ('Options', MarketCategory.options),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final selected = ref.watch(marketScreenerFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (label, category) in _filters)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: label,
                isSelected: selected == category,
                appColors: appColors,
                theme: theme,
                onTap: () {
                  ref.read(marketScreenerFilterProvider.notifier).state =
                      category;
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    final bg = isSelected ? theme.colorScheme.onSurface : Colors.transparent;
    final fg = isSelected ? theme.colorScheme.surface : appColors.subtleText;
    final border = isSelected
        ? theme.colorScheme.onSurface
        : appColors.borderSubtle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: fg,
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
