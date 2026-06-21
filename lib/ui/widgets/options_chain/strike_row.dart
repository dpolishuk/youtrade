import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class OptionStrikeRow {
  const OptionStrikeRow({
    required this.strike,
    required this.isAtm,
    required this.callIv,
    required this.callDelta,
    required this.callMark,
    required this.callColor,
    required this.putIv,
    required this.putDelta,
    required this.putMark,
    required this.putColor,
  });

  final double strike;
  final bool isAtm;
  final double callIv;
  final double callDelta;
  final double callMark;
  final Color callColor;
  final double putIv;
  final double putDelta;
  final double putMark;
  final Color putColor;
}

class StrikeRow extends StatelessWidget {
  const StrikeRow({required this.row, this.isLast = false, super.key});

  final OptionStrikeRow row;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final bg = row.isAtm
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : theme.colorScheme.surface;
    final strikeColor = row.isAtm
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    final cellStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 9.5,
      fontFamily: 'Geist',
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: appColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '${row.callIv.toStringAsFixed(0)}%',
              style: cellStyle?.copyWith(color: appColors.subtleText),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.callDelta.toStringAsFixed(2),
              style: cellStyle?.copyWith(color: appColors.subtleText),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.callMark.toStringAsFixed(4),
              textAlign: TextAlign.right,
              style: cellStyle?.copyWith(
                color: row.callColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatStrike(row.strike),
              textAlign: TextAlign.center,
              style: cellStyle?.copyWith(
                color: strikeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.putMark.toStringAsFixed(4),
              style: cellStyle?.copyWith(
                color: row.putColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.putDelta.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: cellStyle?.copyWith(color: appColors.subtleText),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.putIv.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: cellStyle?.copyWith(color: appColors.subtleText),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStrike(double strike) {
    final formatted = strike.toStringAsFixed(0);
    return formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
