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

      for (final symbol in compareSymbols) {
        expect(chipMaterial(tester, symbol).color, symbol.color);
      }
    });

    testWidgets('allows deselecting from four symbols', (tester) async {
      await tester.pumpWidget(buildSelector(compareSymbols));
      await tester.pumpAndSettle();

      await tester.tap(find.text(compareSymbols[0].symbol));
      await tester.pumpAndSettle();

      expect(
        chipMaterial(tester, compareSymbols[0]).color,
        isNot(compareSymbols[0].color),
      );
      for (var i = 1; i < compareSymbols.length; i++) {
        expect(
          chipMaterial(tester, compareSymbols[i]).color,
          compareSymbols[i].color,
        );
      }
    });
  });
}
