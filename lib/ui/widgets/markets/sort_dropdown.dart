import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/market_screener_provider.dart';
import '../../../presentation/theme/theme_extensions.dart';

/// A compact dropdown that selects the screener sort option and direction.
///
/// Styled to match [FilterChips]. Tapping an already-active option flips the
/// sort direction; selecting a new option resets to descending.
class SortDropdown extends ConsumerWidget {
  const SortDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final sort = ref.watch(marketScreenerSortProvider);

    return PopupMenuButton<SortOption>(
      tooltip: 'Sort by',
      onSelected: (option) {
        final current = ref.read(marketScreenerSortProvider);
        if (current.option == option) {
          ref.read(marketScreenerSortProvider.notifier).state = (
            option: option,
            descending: !current.descending,
          );
        } else {
          ref.read(marketScreenerSortProvider.notifier).state = (
            option: option,
            descending: true,
          );
        }
      },
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      color: theme.cardColor,
      itemBuilder: (context) => [
        for (final option in SortOption.values)
          PopupMenuItem<SortOption>(
            value: option,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sort.option == option)
                  Icon(
                    sort.descending ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 13,
                    color: appColors.accent,
                  )
                else
                  const SizedBox(width: 13),
                const SizedBox(width: 6),
                Text(option.label),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: appColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sort.option.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: appColors.subtleText,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              sort.descending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 13,
              color: appColors.subtleText,
            ),
          ],
        ),
      ),
    );
  }
}
