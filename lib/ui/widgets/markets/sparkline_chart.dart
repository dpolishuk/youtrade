import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class SparklineChart extends StatelessWidget {
  const SparklineChart({required this.data, super.key});

  final List<double> data;

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox.shrink();

    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final first = data.first;
    final last = data.last;
    final color = last >= first ? appColors.bullish : appColors.bearish;

    return CustomPaint(
      size: const Size(46, 24),
      painter: _SparklinePainter(data: data, color: color),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY) == 0 ? 1.0 : maxY - minY;
    const topPad = 2.0;
    final plotHeight = size.height - topPad * 2;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - topPad - ((data[i] - minY) / range) * plotHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
