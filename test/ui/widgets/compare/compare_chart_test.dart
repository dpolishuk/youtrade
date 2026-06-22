import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/compare/compare_chart.dart';
import 'package:youtrade/ui/widgets/compare/compare_models.dart';

void main() {
  group('CompareChart', () {
    Widget buildChart(List<CompareSeries> series) {
      return MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.flux),
        home: Scaffold(body: CompareChart(series: series)),
      );
    }

    testWidgets('renders with 220px height', (tester) async {
      final series = generateCompareSeries([compareSymbols[0]]);
      await tester.pumpWidget(buildChart(series));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CompareChart),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.constraints?.minHeight, 220);
      expect(container.constraints?.maxHeight, 220);
    });

    testWidgets('renders multiple series', (tester) async {
      final series = generateCompareSeries(compareSymbols.sublist(0, 3));
      await tester.pumpWidget(buildChart(series));
      await tester.pumpAndSettle();

      final chart = tester.widget<CompareChart>(find.byType(CompareChart));
      expect(chart.series.length, 3);
    });
  });
}
