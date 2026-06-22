import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/compare/compare_models.dart';
import 'package:youtrade/ui/widgets/compare/symbol_selector.dart';

class _TestSelector extends StatefulWidget {
  const _TestSelector({required this.initial});

  final List<CompareSymbol> initial;

  @override
  State<_TestSelector> createState() => _TestSelectorState();
}

class _TestSelectorState extends State<_TestSelector> {
  late List<CompareSymbol> selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SymbolSelector(
      selected: selected,
      onSelectionChanged: (value) => setState(() => selected = value),
    );
  }
}

void main() {
  Widget buildSelector(List<CompareSymbol> selected) {
    return MaterialApp(
      theme: AppTheme.dark(AppVisualDirection.flux),
      home: Scaffold(body: _TestSelector(initial: selected)),
    );
  }

  Material chipMaterial(WidgetTester tester, CompareSymbol symbol) {
    return tester.widget<Material>(
      find.byKey(ValueKey('symbol_chip_${symbol.symbol}')),
    );
  }

  group('SymbolSelector', () {
    testWidgets('allows deselecting down to one symbol', (tester) async {
      await tester.pumpWidget(
        buildSelector([compareSymbols[0], compareSymbols[1]]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(compareSymbols[0].symbol));
      await tester.pumpAndSettle();

      expect(
        chipMaterial(tester, compareSymbols[0]).color,
        isNot(compareSymbols[0].color),
      );
      expect(
        chipMaterial(tester, compareSymbols[1]).color,
        compareSymbols[1].color,
      );
    });

    testWidgets('prevents deselecting the last symbol', (tester) async {
      await tester.pumpWidget(buildSelector([compareSymbols[0]]));
      await tester.pumpAndSettle();

      await tester.tap(find.text(compareSymbols[0].symbol));
      await tester.pumpAndSettle();

      expect(
        chipMaterial(tester, compareSymbols[0]).color,
        compareSymbols[0].color,
      );
    });

    testWidgets('allows selecting up to four symbols', (tester) async {
      await tester.pumpWidget(
        buildSelector([compareSymbols[0], compareSymbols[1]]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(compareSymbols[2].symbol));
      await tester.pumpAndSettle();

      await tester.tap(find.text(compareSymbols[3].symbol));
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        expect(
          chipMaterial(tester, compareSymbols[i]).color,
          compareSymbols[i].color,
        );
      }
      expect(
        chipMaterial(tester, compareSymbols[4]).color,
        isNot(compareSymbols[4].color),
      );
    });

    testWidgets('evicts oldest symbol when selecting a fifth', (tester) async {
      await tester.pumpWidget(buildSelector(compareSymbols.sublist(0, 4)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(compareSymbols[4].symbol));
      await tester.pumpAndSettle();

      // Oldest (BTC) is evicted; newest (GOLD) is selected.
      expect(
        chipMaterial(tester, compareSymbols[0]).color,
        isNot(compareSymbols[0].color),
      );
      for (var i = 1; i < 5; i++) {
        expect(
          chipMaterial(tester, compareSymbols[i]).color,
          compareSymbols[i].color,
        );
      }
    });

    testWidgets('uses mockup symbol colors', (tester) async {
      await tester.pumpWidget(buildSelector([compareSymbols[0]]));
      await tester.pumpAndSettle();

      expect(compareSymbols[0].color, const Color(0xFF00E6D2));
      expect(compareSymbols[1].color, const Color(0xFFFFB020));
      expect(compareSymbols[2].color, const Color(0xFFFF5D77));
      expect(compareSymbols[3].color, const Color(0xFF8B9CF0));
      expect(compareSymbols[4].color, const Color(0xFFC9A6FF));
    });
  });
}
