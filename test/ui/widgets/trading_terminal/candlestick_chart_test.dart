import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/candle.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
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
    testWidgets('renders MA labels', (tester) async {
      final candles = _candlesWithCloses([10, 10, 10, 1, 1, 1, 1, 1, 1, 1]);
      await tester.pumpWidget(_buildChart(candles));
      await tester.pumpAndSettle();

      expect(find.text('MA7'), findsOneWidget);
      expect(find.text('MA25'), findsOneWidget);
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
