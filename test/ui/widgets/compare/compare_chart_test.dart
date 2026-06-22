import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_extensions.dart';
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

      final decoration = container.decoration! as BoxDecoration;
      final theme = Theme.of(tester.element(find.byType(CompareChart)));
      expect(decoration.color, theme.cardColor);
    });

    testWidgets('applies accent glow box shadow', (tester) async {
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
      final decoration = container.decoration! as BoxDecoration;
      final appColors = Theme.of(
        tester.element(find.byType(CompareChart)),
      ).extension<AppColorTheme>()!;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, hasLength(1));
      expect(decoration.boxShadow!.single.color, appColors.accentGlow);
      expect(decoration.boxShadow!.single.blurRadius, 22);
      expect(decoration.boxShadow!.single.spreadRadius, -10);
    });

    testWidgets('renders multiple series', (tester) async {
      final series = generateCompareSeries(compareSymbols.sublist(0, 3));
      await tester.pumpWidget(buildChart(series));
      await tester.pumpAndSettle();

      final chart = tester.widget<CompareChart>(find.byType(CompareChart));
      expect(chart.series.length, 3);
    });

    testWidgets('LineChart spots match normalized series values', (
      tester,
    ) async {
      final series = generateCompareSeries([compareSymbols[0]]);
      await tester.pumpWidget(buildChart(series));
      await tester.pumpAndSettle();

      // Prevents regression where the container has the correct height but the
      // LineChart is passed empty, shuffled, or otherwise incorrect data.
      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      final barData = lineChart.data.lineBarsData;
      expect(barData.length, 1);

      final spots = barData.single.spots;
      final normalized = series.first.normalized;
      expect(spots.length, normalized.length);
      expect(spots.first.x, 0);
      expect(spots.first.y, closeTo(normalized.first, 1e-9));
      expect(spots.last.x, normalized.length - 1);
      expect(spots.last.y, closeTo(normalized.last, 1e-9));
    });

    testWidgets('series are rendered as straight lines', (tester) async {
      final series = generateCompareSeries(compareSymbols.sublist(0, 3));
      await tester.pumpWidget(buildChart(series));
      await tester.pumpAndSettle();

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      for (final bar in lineChart.data.lineBarsData) {
        expect(bar.isCurved, isFalse);
      }
    });
  });
}
