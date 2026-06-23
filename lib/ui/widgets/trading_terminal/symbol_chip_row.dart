import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/symbol_metadata.dart';
import '../../../domain/entities/venue.dart';
import '../../../presentation/providers/selected_symbol_provider.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/theme/theme_extensions.dart';

final _chipSymbols = [
  TradingSymbol(
    base: 'BTC',
    quote: 'USDT',
    venue: Venue.binance,
    rawSymbol: 'BTCUSDT',
  ),
  TradingSymbol(
    base: 'ETH',
    quote: 'USDT',
    venue: Venue.binance,
    rawSymbol: 'ETHUSDT',
  ),
  TradingSymbol(
    base: 'SOL',
    quote: 'USDT',
    venue: Venue.binance,
    rawSymbol: 'SOLUSDT',
  ),
  TradingSymbol(
    base: 'AAPL',
    quote: 'USD',
    venue: Venue.coinbase,
    rawSymbol: 'AAPL',
  ),
  TradingSymbol(
    base: 'GOLD',
    quote: 'USD',
    venue: Venue.okx,
    rawSymbol: 'GC=F',
  ),
];

class SymbolChipRow extends ConsumerWidget {
  const SymbolChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSymbolProvider);
    final appColors = Theme.of(context).extension<AppColorTheme>()!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Row(
        children: [
          for (final chip in _chipSymbols)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _SymbolChip(
                key: ValueKey('symbol_chip_${chipLabel(chip.rawSymbol)}'),
                label: chipLabel(chip.rawSymbol),
                isSelected:
                    selected.rawSymbol == chip.rawSymbol ||
                    chipLabel(selected.rawSymbol) == chipLabel(chip.rawSymbol),
                onTap: () {
                  ref.read(selectedSymbolProvider.notifier).state = chip;
                },
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
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.appColors,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorTheme appColors;

  @override
  Widget build(BuildContext context) {
    final accent = appColors.accent;
    final bg = isSelected ? accent.withValues(alpha: 0.15) : appColors.chip;
    final border = isSelected
        ? accent.withValues(alpha: 0.4)
        : appColors.borderSubtle;
    final fg = isSelected ? accent : appColors.subtleText;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: AppTheme.mono(
              color: fg,
              fontSize: 11,
            ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.02),
          ),
        ),
      ),
    );
  }
}
