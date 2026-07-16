import 'package:flutter/material.dart';

import '../../../domain/entities/options_chain_strike.dart';
import '../../../presentation/theme/theme_extensions.dart';

class StrikeRow extends StatelessWidget {
  const StrikeRow({required this.row, this.isLast = false, super.key});

  final OptionChainStrike row;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final bg = row.isAtm ? appColors.accent.withValues(alpha: 0.08) : null;
    final strikeColor = row.isAtm
        ? appColors.accent
        : theme.colorScheme.onSurface;
    final cellStyle = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 9.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final callColor = row.callInTheMoney
        ? appColors.bullish
        : appColors.subtleText;
    final putColor = row.callInTheMoney
        ? appColors.subtleText
        : appColors.bearish;

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
            child: Text(
              '${row.callIv.toStringAsFixed(0)}%',
              style: cellStyle.copyWith(color: appColors.tertiaryText),
            ),
          ),
          Expanded(
            child: Text(
              row.callDelta.toStringAsFixed(2),
              style: cellStyle.copyWith(color: appColors.subtleText),
            ),
          ),
          Expanded(
            child: Text(
              row.callMark.toStringAsFixed(4),
              textAlign: TextAlign.right,
              style: cellStyle.copyWith(
                color: callColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatStrike(row.strike),
              textAlign: TextAlign.center,
              style: cellStyle.copyWith(
                color: strikeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.putMark.toStringAsFixed(4),
              style: cellStyle.copyWith(
                color: putColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.putDelta.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: cellStyle.copyWith(color: appColors.subtleText),
            ),
          ),
          Expanded(
            child: Text(
              '${row.putIv.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: cellStyle.copyWith(color: appColors.tertiaryText),
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
