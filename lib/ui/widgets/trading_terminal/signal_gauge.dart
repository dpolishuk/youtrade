import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

import '../../../domain/entities/candle.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/ticker.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'formatting.dart';

class SignalGauge extends StatelessWidget {
  const SignalGauge({
    required this.symbol,
    required this.ticker,
    required this.candles,
    super.key,
  });

  final TradingSymbol symbol;
  final Ticker? ticker;
  final List<Candle> candles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    final price =
        ticker?.lastPrice ?? (candles.isNotEmpty ? candles.first.close : 0);
    final score = _computeScore();
    final verdict = _verdict(score);
    final verdictColor = score > 70
        ? appColors.bullish
        : score < 30
        ? appColors.bearish
        : appColors.subtleText;
    final buyCount = score ~/ 10;
    final sellCount = 10 - buyCount;

    final oscillators = _buildOscillators(price);
    final movingAverages = _buildMovingAverages(price);
    final pivots = _buildPivots(price);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 120,
              height: 66,
              child: _GaugePainter(
                score: score,
                appColors: appColors,
                theme: theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    verdict,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: verdictColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$buyCount buy · $sellCount sell signals',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: appColors.subtleText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Oscillator score $score/100',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: appColors.subtleText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle('Oscillators'),
        _SignalTable(rows: oscillators, appColors: appColors, theme: theme),
        const SizedBox(height: 14),
        _SectionTitle('Moving averages'),
        _SignalTable(rows: movingAverages, appColors: appColors, theme: theme),
        const SizedBox(height: 14),
        _SectionTitle('Pivot levels'),
        _PivotGrid(pivots: pivots, appColors: appColors, theme: theme),
      ],
    );
  }

  int _computeScore() {
    final change = ticker?.change24hPercent ?? 0;
    return ((change * 5000 + 50).clamp(0, 100)).toInt();
  }

  String _verdict(int score) {
    if (score >= 80) return 'Strong Buy';
    if (score >= 60) return 'Buy';
    if (score >= 40) return 'Neutral';
    if (score >= 20) return 'Sell';
    return 'Strong Sell';
  }

  List<_SignalRow> _buildOscillators(double price) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    return [
      _SignalRow(
        'RSI (14)',
        _jitter(price, 0.02).toStringAsFixed(2),
        'Neutral',
        appColors.subtleText,
      ),
      _SignalRow(
        'MACD (12,26)',
        _jitter(price, 0.01).toStringAsFixed(2),
        'Buy',
        appColors.bullish,
      ),
      _SignalRow(
        'Stoch (14,3,3)',
        _jitter(price, 0.03).toStringAsFixed(2),
        'Sell',
        appColors.bearish,
      ),
      _SignalRow(
        'CCI (20)',
        _jitter(price, 0.015).toStringAsFixed(2),
        'Neutral',
        appColors.subtleText,
      ),
      _SignalRow(
        'Momentum (10)',
        _jitter(price, 0.025).toStringAsFixed(2),
        'Buy',
        appColors.bullish,
      ),
    ];
  }

  List<_SignalRow> _buildMovingAverages(double price) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    return [
      _SignalRow(
        'MA10',
        formatPrice(price * 0.998, maxDecimals: 2),
        'Buy',
        appColors.bullish,
      ),
      _SignalRow(
        'MA20',
        formatPrice(price * 0.995, maxDecimals: 2),
        'Buy',
        appColors.bullish,
      ),
      _SignalRow(
        'MA50',
        formatPrice(price * 0.985, maxDecimals: 2),
        'Buy',
        appColors.bullish,
      ),
      _SignalRow(
        'MA100',
        formatPrice(price * 0.97, maxDecimals: 2),
        'Neutral',
        appColors.subtleText,
      ),
      _SignalRow(
        'MA200',
        formatPrice(price * 0.94, maxDecimals: 2),
        'Sell',
        appColors.bearish,
      ),
    ];
  }

  List<_Pivot> _buildPivots(double price) {
    return [
      _Pivot('S2', price * 0.96),
      _Pivot('S1', price * 0.98),
      _Pivot('PP', price),
      _Pivot('R1', price * 1.02),
      _Pivot('R2', price * 1.04),
    ];
  }

  double _jitter(double base, double factor) {
    return base * (1 + factor);
  }
}

class _GaugePainter extends StatelessWidget {
  const _GaugePainter({
    required this.score,
    required this.appColors,
    required this.theme,
  });

  final int score;
  final AppColorTheme appColors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 66),
      painter: _GaugeArcPainter(
        score: score,
        appColors: appColors,
        theme: theme,
      ),
    );
  }
}

class _GaugeArcPainter extends CustomPainter {
  _GaugeArcPainter({
    required this.score,
    required this.appColors,
    required this.theme,
  });

  final int score;
  final AppColorTheme appColors;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.09;
    final radius = size.width / 2 - strokeWidth;
    final center = Offset(size.width / 2, size.height - strokeWidth / 2);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    void drawArc(double startAngle, double sweepAngle, Color color) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint..color = color,
      );
    }

    drawArc(pi, pi * 0.32, appColors.bearish.withOpacity(0.7));
    drawArc(pi + pi * 0.34, pi * 0.32, appColors.subtleText.withOpacity(0.7));
    drawArc(pi + pi * 0.68, pi * 0.32, appColors.bullish.withOpacity(0.7));

    final angle = pi + (score / 100) * pi;
    final needleLength = radius - strokeWidth;
    final needleEnd = Offset(
      center.dx + needleLength * cos(angle),
      center.dy + needleLength * sin(angle),
    );

    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = theme.colorScheme.onSurface
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      center,
      4.5,
      Paint()..color = theme.colorScheme.onSurface,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: appColors.subtleText,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _SignalRow {
  const _SignalRow(this.name, this.value, this.signal, this.signalColor);

  final String name;
  final String value;
  final String signal;
  final Color signalColor;
}

class _SignalTable extends StatelessWidget {
  const _SignalTable({
    required this.rows,
    required this.appColors,
    required this.theme,
  });

  final List<_SignalRow> rows;
  final AppColorTheme appColors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: appColors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border(
                  bottom: i < rows.length - 1
                      ? BorderSide(color: appColors.borderSubtle)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: appColors.subtleText,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        rows[i].value,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 64,
                        child: Text(
                          rows[i].signal,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: rows[i].signalColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Pivot {
  const _Pivot(this.label, this.value);

  final String label;
  final double value;
}

class _PivotGrid extends StatelessWidget {
  const _PivotGrid({
    required this.pivots,
    required this.appColors,
    required this.theme,
  });

  final List<_Pivot> pivots;
  final AppColorTheme appColors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appColors.borderSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < pivots.length; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: i == 0 ? 0 : 1),
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Column(
                  children: [
                    Text(
                      pivots[i].label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: appColors.subtleText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(pivots[i].value, maxDecimals: 2),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
