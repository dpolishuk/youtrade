import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/portfolio/equity_curve.dart';

void main() {
  group('EquityCurve', () {
    testWidgets('renders straight line segments', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(AppVisualDirection.flux),
          home: const Scaffold(
            body: EquityCurve(data: [100, 102, 101, 103, 104]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lineChartBar = tester
          .widget<LineChart>(find.byType(LineChart))
          .data
          .lineBarsData
          .first;
      expect(lineChartBar.isCurved, isFalse);
    });
  });
}
