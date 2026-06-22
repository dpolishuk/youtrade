import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_extensions.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/widgets/trading_terminal/candlestick_chart.dart';

Widget _buildChart(List<Candle> candles) {
  return MaterialApp(
    theme: AppTheme.dark(AppVisualDirection.flux),
    home: Scaffold(body: CandlestickChart(candles: candles)),
  );
}

List<Candle> _candlesWithCloses(List<double> closes) {
  final now = DateTime.utc(2026, 1, 1);
  return List.generate(
    closes.length,
    (i) => Candle(
      open: closes[i],
      high: closes[i] + 1,
      low: closes[i] - 1,
      close: closes[i],
      volume: 100,
      timestamp: now.add(Duration(hours: i)),
    ),
  );
}

void main() {
  group('CandlestickChart', () {
    testWidgets('renders MA labels and painted price area', (tester) async {
      final candles = _candlesWithCloses([10, 10, 10, 1, 1, 1, 1, 1, 1, 1]);
      await tester.pumpWidget(_buildChart(candles));
      await tester.pumpAndSettle();

      expect(find.text('MA7'), findsOneWidget);
      expect(find.text('MA25'), findsOneWidget);

      // Prevents regression where non-empty candle data still shows the empty
      // loading state instead of the painted chart.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Prevents regression where the chart is laid out at zero size and the
      // axis price labels (painted by _CandlestickPainter) are not visible.
      final customPaint = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(CandlestickChart),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(customPaint.size, isNot(equals(Size.zero)));
      expect(customPaint.size.height, 248);
      expect(customPaint.size.width, greaterThan(0));
      expect(customPaint.painter, isNotNull);

      // Prevents regression where the glow token is hard-coded instead of using
      // the theme directional glow color.
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CandlestickChart),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final boxShadow = decoration.boxShadow!.first;
      final accentGlow = AppTheme.dark(
        AppVisualDirection.flux,
      ).extension<AppColorTheme>()!.accentGlow;
      expect(boxShadow.color, accentGlow);
    });

    testWidgets('shows progress indicator when candles are empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildChart(const <Candle>[]));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
