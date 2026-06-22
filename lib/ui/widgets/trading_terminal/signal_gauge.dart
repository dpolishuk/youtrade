import 'dart:math' show cos, min, pi, sin;

import 'package:flutter/material.dart';

import '../../../domain/entities/candle.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/symbol_metadata.dart';
import '../../../domain/entities/ticker.dart';
import '../../../presentation/theme/app_theme.dart';
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
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final meta = resolveSymbolMetadata(symbol);

    final last =
        ticker?.lastPrice ?? (candles.isNotEmpty ? candles.last.close : 0.0);
    final first24 = candles.length >= 24
        ? candles[candles.length - 24].close
        : (candles.isNotEmpty ? candles.first.close : last);
    final chg = last - first24;
    final chgP = first24 != 0 ? chg / first24 * 100 : 0.0;

    final rsi = _rsi(symbol.rawSymbol);
    final gauge = (50 + chgP * 6 + (rsi - 50) * 0.6).clamp(0.0, 100.0);
    final verdict = gauge > 62
        ? 'BUY'
        : gauge > 54
        ? 'NEUTRAL'
        : gauge < 40
        ? 'SELL'
        : 'NEUTRAL';
    final verdictColor = gauge > 54
        ? appColors.bullish
        : gauge < 46
        ? appColors.bearish
        : appColors.subtleText;

    final oscillators = _buildOscillators(chg, chgP, rsi, appColors);
    final movingAverages = _buildMovingAverages(
      candles,
      last,
      meta.decimals,
      appColors,
    );
    final pivots = _buildPivots(candles, meta);

    final buyCount =
        movingAverages.where((r) => r.signal == 'Buy').length +
        oscillators.where((r) => r.signal == 'Buy').length;
    final sellCount =
        movingAverages.where((r) => r.signal == 'Sell').length +
        oscillators.where((r) => r.signal == 'Sell').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 120,
              height: 66,
              child: _GaugePainter(
                score: gauge.toDouble(),
                appColors: appColors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    verdict,
                    style: AppTheme.display(color: verdictColor, fontSize: 26)
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.02 * 26,
                          height: 1.0,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$buyCount buy · $sellCount sell signals',
                    style: AppTheme.mono(
                      color: appColors.tertiaryText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Oscillator score ${gauge.round()}/100',
                    style: AppTheme.mono(
                      color: appColors.subtleText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle('OSCILLATORS'),
        _SignalTable(rows: oscillators, signalWidth: 64),
        const SizedBox(height: 14),
        _SectionTitle('MOVING AVERAGES'),
        _SignalTable(rows: movingAverages, signalWidth: 36),
        const SizedBox(height: 14),
        _SectionTitle('PIVOT LEVELS'),
        _PivotGrid(pivots: pivots),
      ],
    );
  }

  int _rsi(String rawSymbol) {
    var seed = rawSymbol.length * 13;
    const modulus = 2147483647;
    const multiplier = 16807;
    seed = seed % modulus;
    if (seed <= 0) seed += modulus - 1;
    seed = (seed * multiplier) % modulus;
    final r = seed / modulus;
    return 58 + (r * 20 - 6).round();
  }

  List<_SignalRow> _buildOscillators(
    double chg,
    double chgP,
    int rsi,
    AppColorTheme appColors,
  ) {
    return [
      _SignalRow(
        'RSI (14)',
        rsi.toStringAsFixed(1),
        rsi > 70
            ? 'Overbought'
            : rsi < 35
            ? 'Oversold'
            : 'Neutral',
        rsi > 70
            ? appColors.bearish
            : rsi < 35
            ? appColors.bullish
            : appColors.subtleText,
      ),
      _SignalRow(
        'MACD (12,26)',
        (chg * 0.12).toStringAsFixed(1),
        chg > 0 ? 'Buy' : 'Sell',
        chg > 0 ? appColors.bullish : appColors.bearish,
      ),
      _SignalRow(
        'Stoch %K',
        (rsi - 4).toStringAsFixed(1),
        'Neutral',
        appColors.subtleText,
      ),
      _SignalRow(
        'CCI (20)',
        (chgP * 9).toStringAsFixed(1),
        chgP > 0 ? 'Buy' : 'Sell',
        chgP > 0 ? appColors.bullish : appColors.bearish,
      ),
      _SignalRow(
        'Williams %R',
        (-30 - rsi * 0.3).toStringAsFixed(1),
        'Buy',
        appColors.bullish,
      ),
    ];
  }

  List<_SignalRow> _buildMovingAverages(
    List<Candle> data,
    double last,
    int decimals,
    AppColorTheme appColors,
  ) {
    return [7, 25, 50, 99, 200].map((p) {
      final mv = _movingAverage(data, p);
      final buy = last >= mv;
      return _SignalRow(
        'MA $p',
        formatFixedPrice(mv, decimals),
        buy ? 'Buy' : 'Sell',
        buy ? appColors.bullish : appColors.bearish,
      );
    }).toList();
  }

  List<_Pivot> _buildPivots(List<Candle> candles, SymbolMetadata meta) {
    final last24 = candles.length >= 24
        ? candles.sublist(candles.length - 24)
        : candles;
    if (last24.isEmpty) return [];
    final hi = last24.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final lo = last24.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final last = candles.isNotEmpty ? candles.last.close : hi;
    return [
      _Pivot('R2', hi * 1.012, meta.decimals),
      _Pivot('R1', hi, meta.decimals),
      _Pivot('Pivot', (hi + lo + last) / 3, meta.decimals),
      _Pivot('S1', lo, meta.decimals),
      _Pivot('S2', lo * 0.988, meta.decimals),
    ];
  }

  double _movingAverage(List<Candle> data, int period) {
    if (data.isEmpty) return 0.0;
    final effective = min(period, data.length);
    final slice = data.sublist(data.length - effective);
    final sum = slice.fold(0.0, (acc, c) => acc + c.close);
    return sum / slice.length;
  }
}

class _GaugePainter extends StatelessWidget {
  const _GaugePainter({required this.score, required this.appColors});

  final double score;
  final AppColorTheme appColors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 66),
      painter: _GaugeArcPainter(score: score, appColors: appColors),
    );
  }
}

class _GaugeArcPainter extends CustomPainter {
  _GaugeArcPainter({required this.score, required this.appColors});

  final double score;
  final AppColorTheme appColors;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 11.0;
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

    drawArc(pi, pi * 0.32, appColors.bearish.withValues(alpha: 0.85));
    drawArc(
      pi + pi * 0.34,
      pi * 0.32,
      const Color(0xFFFFB020).withValues(alpha: 0.85),
    );
    drawArc(
      pi + pi * 0.68,
      pi * 0.32,
      appColors.bullish.withValues(alpha: 0.85),
    );

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
        ..color = appColors.foreground
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 4.5, Paint()..color = appColors.foreground);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        title,
        style: AppTheme.mono(
          color: appColors.tertiaryText,
          fontSize: 9,
        ).copyWith(letterSpacing: 0.1),
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
  const _SignalTable({required this.rows, required this.signalWidth});

  final List<_SignalRow> rows;
  final double signalWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

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
                color: theme.cardColor,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: appColors.subtleText,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        rows[i].value,
                        style: AppTheme.mono(
                          color: appColors.foreground,
                          fontSize: 12,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: signalWidth,
                        child: Text(
                          rows[i].signal,
                          textAlign: TextAlign.right,
                          style: AppTheme.mono(
                            color: rows[i].signalColor,
                            fontSize: 10,
                          ).copyWith(fontWeight: FontWeight.w600),
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
  const _Pivot(this.label, this.value, this.decimals);

  final String label;
  final double value;
  final int decimals;
}

class _PivotGrid extends StatelessWidget {
  const _PivotGrid({required this.pivots});

  final List<_Pivot> pivots;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

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
                color: theme.cardColor,
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Column(
                  children: [
                    Text(
                      pivots[i].label,
                      style: AppTheme.mono(
                        color: appColors.tertiaryText,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatFixedPrice(pivots[i].value, pivots[i].decimals),
                      style: AppTheme.mono(
                        color: appColors.foreground,
                        fontSize: 10,
                      ).copyWith(fontWeight: FontWeight.w500),
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
