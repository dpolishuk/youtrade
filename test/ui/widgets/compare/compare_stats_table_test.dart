import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_extensions.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/compare/compare_models.dart';
import 'package:youtrade/ui/widgets/compare/compare_stats_table.dart';

void main() {
  group('CompareStatsTable', () {
    Widget buildTable(List<CompareSeries> series) {
      return MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.flux),
        home: Scaffold(body: CompareStatsTable(series: series)),
      );
    }

    testWidgets('shows headers', (tester) async {
      final series = generateCompareSeries([compareSymbols[0]]);
      await tester.pumpWidget(buildTable(series));
      await tester.pumpAndSettle();

      expect(find.text('SYMBOL'), findsOneWidget);
      expect(find.text('RETURN'), findsOneWidget);
      expect(find.text('VOLATILITY'), findsOneWidget);
    });

    testWidgets('container and rows use card background', (tester) async {
      final series = generateCompareSeries(compareSymbols.sublist(0, 3));
      await tester.pumpWidget(buildTable(series));
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(CompareStatsTable)));
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(CompareStatsTable),
          matching: find.byType(Container),
        ),
      );
      expect(containers, isNotEmpty);
      for (final container in containers) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          expect(decoration.color, theme.cardColor);
        }
      }
    });

    testWidgets('renders one row per series', (tester) async {
      final series = generateCompareSeries(compareSymbols.sublist(0, 3));
      await tester.pumpWidget(buildTable(series));
      await tester.pumpAndSettle();

      for (final s in series) {
        expect(find.text(s.symbol.symbol), findsOneWidget);
      }
    });

    testWidgets('return column shows exact positive return and bullish color', (
      tester,
    ) async {
      final series = generateCompareSeries([compareSymbols[0]]);
      await tester.pumpWidget(buildTable(series));
      await tester.pumpAndSettle();

      // Prevents regression where the return column is rendered in the wrong
      // color or with the wrong formatted value.
      final expectedColor = AppTheme.dark(
        AppVisualDirection.flux,
      ).extension<AppColorTheme>()!.bullish;
      final returnText = tester.widget<Text>(find.text('+12.80%'));
      expect(returnText.style?.color, expectedColor);
    });
  });
}
