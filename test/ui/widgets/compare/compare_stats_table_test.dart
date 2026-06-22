import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
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

      expect(find.text('Symbol'), findsOneWidget);
      expect(find.text('Return'), findsOneWidget);
      expect(find.text('Volatility'), findsOneWidget);
    });

    testWidgets('renders one row per series', (tester) async {
      final series = generateCompareSeries(compareSymbols.sublist(0, 3));
      await tester.pumpWidget(buildTable(series));
      await tester.pumpAndSettle();

      for (final s in series) {
        expect(find.text(s.symbol.symbol), findsOneWidget);
      }
    });

    testWidgets('return column uses up color for positive return', (
      tester,
    ) async {
      final series = generateCompareSeries([compareSymbols[0]]);
      await tester.pumpWidget(buildTable(series));
      await tester.pumpAndSettle();

      final returnText = tester.widget<Text>(
        find.text(
          '${series.first.totalReturn >= 0 ? '+' : ''}${series.first.totalReturn.toStringAsFixed(2)}%',
        ),
      );
      expect(returnText.style?.color, isNotNull);
    });
  });
}
