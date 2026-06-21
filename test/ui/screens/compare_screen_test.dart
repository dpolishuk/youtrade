import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/compare_screen.dart';
import 'package:youtrade/ui/widgets/compare/compare_chart.dart';
import 'package:youtrade/ui/widgets/compare/symbol_selector.dart';

void main() {
  group('CompareScreen', () {
    Widget buildScreen() {
      return MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.flux),
        home: const CompareScreen(),
      );
    }

    testWidgets('renders without overflow and shows chart and selectors', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Compare'), findsWidgets);
      expect(find.byType(CompareChart), findsOneWidget);
      expect(find.byType(SymbolSelector), findsOneWidget);
      expect(find.text('BTC'), findsWidgets);
      expect(find.text('ETH'), findsWidgets);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('tapping a time range chip updates the selected range', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('3M'));
      await tester.pumpAndSettle();

      expect(find.text('3M'), findsOneWidget);
      expect(find.byType(CompareChart), findsOneWidget);
    });
  });
}
