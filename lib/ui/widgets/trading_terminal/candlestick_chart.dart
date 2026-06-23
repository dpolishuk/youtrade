import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/entities/candle.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'formatting.dart';

class CandlestickChart extends StatelessWidget {
  const CandlestickChart({required this.candles, super.key});

  final List<Candle> candles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 248,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: appColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: appColors.accentGlow,
              blurRadius: 22,
              spreadRadius: -10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: candles.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      CustomPaint(
                        size: Size(constraints.maxWidth, 248),
                        painter: _CandlestickPainter(
                          candles: candles,
                          appColors: appColors,
                          surfaceColor: theme.colorScheme.surface,
                        ),
                      ),
                      Positioned(
                        top: 7,
                        left: 10,
                        child: Row(
                          children: [
                            _MaLabel(
                              label: 'MA7',
                              color: appColors.accent.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 9),
                            const _MaLabel(
                              label: 'MA25',
                              color: Color(0xFFFFB020),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _MaLabel extends StatelessWidget {
  const _MaLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTheme.mono(
        color: color,
        fontSize: 9,
      ).copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  _CandlestickPainter({
    required this.candles,
    required this.appColors,
    required this.surfaceColor,
  });

  final List<Candle> candles;
  final AppColorTheme appColors;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    const padR = 52.0;
    const padT = 8.0;
    const volH = 46.0;
    const gap = 10.0;
    const axisLabelH = 16.0;
    final priceH = size.height - padT - volH - gap - axisLabelH;
    final n = min(48, candles.length);
    final view = candles.sublist(candles.length - n);
    final offset = candles.length - n;

    var hi = view.map((c) => c.high).reduce(max);
    var lo = view.map((c) => c.low).reduce(min);
    var vmax = view.map((c) => c.volume).reduce(max);
    if (hi == lo) {
      hi += 1;
      lo -= 1;
    }
    if (vmax == 0) vmax = 1;
    final pad = (hi - lo) * 0.08;
    hi += pad;
    lo -= pad;

    final plotW = size.width - padR;
    final cw = plotW / n;
    final bw = max(2.0, cw * 0.62);
    final priceBottom = padT + priceH;
    final volBottom = size.height - axisLabelH;

    double y(double p) => padT + (hi - p) / (hi - lo) * priceH;
    double vy(double v) => priceBottom + gap + (volH - v / vmax * volH);

    _drawGrid(canvas, plotW, hi, lo, y);
    _drawMA(
      canvas,
      view,
      offset,
      cw,
      y,
      7,
      appColors.accent.withValues(alpha: 0.9),
    );
    _drawMA(
      canvas,
      view,
      offset,
      cw,
      y,
      25,
      const Color(0xFFFFB020).withValues(alpha: 0.85),
    );
    _drawCandles(canvas, view, cw, bw, y, vy, volBottom);
    _drawLastPriceLine(canvas, view.last, plotW, y);
    _drawCrosshair(canvas, view, n, cw, y, plotW, priceBottom);
  }

  void _drawGrid(
    Canvas canvas,
    double plotW,
    double hi,
    double lo,
    double Function(double) y,
  ) {
    final gridPaint = Paint()
      ..color = appColors.grid
      ..strokeWidth = 1;

    for (var g = 0; g <= 4; g++) {
      final p = hi - (hi - lo) * g / 4;
      final py = y(p);
      canvas.drawLine(Offset(0, py), Offset(plotW, py), gridPaint);
      _drawText(
        canvas,
        formatAxisNumber(p),
        Offset(plotW + 6, py),
        AppTheme.mono(color: appColors.tertiaryText, fontSize: 9),
        centerVertical: true,
      );
    }
  }

  void _drawMA(
    Canvas canvas,
    List<Candle> view,
    int offset,
    double cw,
    double Function(double) y,
    int period,
    Color color,
  ) {
    final path = Path();
    for (var i = 0; i < view.length; i++) {
      final ma = _movingAverage(candles, period, offset + i);
      final x = i * cw + cw / 2;
      final py = y(ma);
      if (i == 0) {
        path.moveTo(x, py);
      } else {
        path.lineTo(x, py);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawCandles(
    Canvas canvas,
    List<Candle> view,
    double cw,
    double bw,
    double Function(double) y,
    double Function(double) vy,
    double volBottom,
  ) {
    for (var i = 0; i < view.length; i++) {
      final c = view[i];
      final x = i * cw + cw / 2;
      final up = c.close >= c.open;
      final col = up ? appColors.bullish : appColors.bearish;

      final volTop = vy(c.volume);
      canvas.drawRect(
        Rect.fromLTWH(i * cw + (cw - bw) / 2, volTop, bw, volBottom - volTop),
        Paint()..color = col.withValues(alpha: 0.32),
      );

      canvas.drawLine(
        Offset(x, y(c.high)),
        Offset(x, y(c.low)),
        Paint()
          ..color = col
          ..strokeWidth = 1,
      );

      final yo = y(c.open);
      final yc = y(c.close);
      canvas.drawRect(
        Rect.fromLTWH(
          i * cw + (cw - bw) / 2,
          min(yo, yc),
          bw,
          max(1.5, (yo - yc).abs()),
        ),
        Paint()..color = col,
      );
    }
  }

  void _drawLastPriceLine(
    Canvas canvas,
    Candle last,
    double plotW,
    double Function(double) y,
  ) {
    final up = last.close >= last.open;
    final col = up ? appColors.bullish : appColors.bearish;
    final ly = y(last.close);

    final path = Path()
      ..moveTo(0, ly)
      ..lineTo(plotW, ly);
    canvas.drawPath(
      _dashPath(path, const [3.0, 3.0]),
      Paint()
        ..color = col.withValues(alpha: 0.6)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    canvas.drawRect(Rect.fromLTWH(plotW, ly - 8, 52, 16), Paint()..color = col);

    _drawText(
      canvas,
      formatAxisNumber(last.close),
      Offset(plotW + 5, ly),
      AppTheme.mono(color: Colors.white, fontSize: 9),
      centerVertical: true,
    );
  }

  void _drawCrosshair(
    Canvas canvas,
    List<Candle> view,
    int n,
    double cw,
    double Function(double) y,
    double plotW,
    double priceBottom,
  ) {
    final ci = (n * 0.66).floor();
    final cx = ci * cw + cw / 2;
    final cc = view[ci];

    final dashedPaint = Paint()
      ..color = appColors.borderSubtle
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final vertical = Path()
      ..moveTo(cx, 0)
      ..lineTo(cx, priceBottom);
    canvas.drawPath(_dashPath(vertical, const [2.0, 3.0]), dashedPaint);

    final cyl = y(cc.high) - 6;
    final horizontal = Path()
      ..moveTo(0, cyl)
      ..lineTo(plotW, cyl);
    canvas.drawPath(_dashPath(horizontal, const [2.0, 3.0]), dashedPaint);

    canvas.drawRect(
      Rect.fromLTWH(plotW, cyl - 8, 52, 16),
      Paint()..color = appColors.subtleText,
    );

    _drawText(
      canvas,
      formatAxisNumber(cc.high),
      Offset(plotW + 5, cyl),
      AppTheme.mono(color: surfaceColor, fontSize: 9),
      centerVertical: true,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required bool centerVertical,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    final dy = centerVertical ? offset.dy - painter.height / 2 : offset.dy;
    painter.paint(canvas, Offset(offset.dx, dy));
  }

  Path _dashPath(Path source, List<double> pattern) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var index = 0;
      var draw = true;
      while (distance < metric.length) {
        final length = pattern[index % pattern.length];
        final next = min(distance + length, metric.length);
        final segment = metric.extractPath(distance, next);
        if (draw) dashed.addPath(segment, Offset.zero);
        distance = next;
        index++;
        draw = !draw;
      }
    }
    return dashed;
  }

  double _movingAverage(List<Candle> data, int period, int index) {
    final start = max(0, index - period + 1);
    final slice = data.sublist(start, index + 1);
    final sum = slice.fold(0.0, (acc, c) => acc + c.close);
    return sum / slice.length;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
