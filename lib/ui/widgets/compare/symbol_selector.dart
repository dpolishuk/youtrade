import 'package:flutter/material.dart';

import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'compare_models.dart';

/// Horizontal scrollable selector for 1-4 comparison symbols.
class SymbolSelector extends StatelessWidget {
  const SymbolSelector({
    required this.selected,
    required this.onSelectionChanged,
    super.key,
  });

  final List<CompareSymbol> selected;
  final ValueChanged<List<CompareSymbol>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final symbol in compareSymbols)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _SymbolChip(
                symbol: symbol,
                isSelected: selected.any((s) => s.symbol == symbol.symbol),
                onTap: () => _toggle(symbol),
                appColors: appColors,
              ),
            ),
        ],
      ),
    );
  }

  void _toggle(CompareSymbol symbol) {
    final currentlySelected = List<CompareSymbol>.from(selected);
    final index = currentlySelected.indexWhere(
      (s) => s.symbol == symbol.symbol,
    );

    if (index >= 0) {
      if (currentlySelected.length > 1) {
        currentlySelected.removeAt(index);
      } else {
        return;
      }
    } else if (currentlySelected.length < 4) {
      currentlySelected.add(symbol);
    } else {
      currentlySelected
        ..removeAt(0)
        ..add(symbol);
    }

    onSelectionChanged(currentlySelected);
  }
}

class _SymbolChip extends StatelessWidget {
  const _SymbolChip({
    required this.symbol,
    required this.isSelected,
    required this.onTap,
    required this.appColors,
  });

  final CompareSymbol symbol;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorTheme appColors;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? symbol.color : appColors.chip;
    final border = isSelected ? symbol.color : appColors.borderSubtle;
    final fg = isSelected ? Colors.white : appColors.subtleText;

    return Material(
      key: ValueKey('symbol_chip_${symbol.symbol}'),
      color: bg,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: border),
          ),
          child: Text(
            symbol.symbol,
            style: AppTheme.mono(
              color: fg,
              fontSize: 11,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
