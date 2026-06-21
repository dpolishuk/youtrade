import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/venue.dart';
import '../../../presentation/providers/selected_symbol_provider.dart';
import '../../../presentation/theme/theme_extensions.dart';

final _chips = [
  const _ChipData(base: 'BTC', quote: 'USDT'),
  const _ChipData(base: 'ETH', quote: 'USDT'),
  const _ChipData(base: 'SOL', quote: 'USDT'),
  const _ChipData(base: 'XRP', quote: 'USDT'),
  const _ChipData(base: 'DOGE', quote: 'USDT'),
];

class _ChipData {
  const _ChipData({required this.base, required this.quote});

  final String base;
  final String quote;
}

class SymbolChipRow extends ConsumerWidget {
  const SymbolChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSymbolProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColorTheme>()!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final chip in _chips)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _SymbolChip(
                label: '${chip.base}/${chip.quote}',
                isSelected:
                    selected.base == chip.base && selected.quote == chip.quote,
                onTap: () {
                  ref
                      .read(selectedSymbolProvider.notifier)
                      .state = TradingSymbol(
                    base: chip.base,
                    quote: chip.quote,
                    venue: Venue.binance,
                    rawSymbol: '${chip.base}${chip.quote}',
                  );
                },
                colorScheme: colorScheme,
                appColors: appColors,
              ),
            ),
        ],
      ),
    );
  }
}

class _SymbolChip extends StatelessWidget {
  const _SymbolChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.appColors,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final AppColorTheme appColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? colorScheme.primary : colorScheme.surface,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isSelected ? colorScheme.primary : appColors.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
