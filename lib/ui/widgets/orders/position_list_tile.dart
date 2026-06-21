import 'package:flutter/material.dart';

import '../../../domain/entities/position.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'status_badge.dart';

/// Row-style tile for an open position.
class PositionListTile extends StatelessWidget {
  const PositionListTile({required this.position, super.key});

  final Position position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final sideColor = position.isLong ? appColors.bullish : appColors.bearish;
    final sideTint = position.isLong
        ? appColors.bullish.withValues(alpha: 0.16)
        : appColors.bearish.withValues(alpha: 0.16);
    final pnlColor = _parsePnl(position.pnl) >= 0
        ? appColors.bullish
        : appColors.bearish;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: position.tint,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              position.sym0,
              style: theme.textTheme.labelLarge?.copyWith(
                color: position.iconColor,
                fontWeight: FontWeight.w600,
                fontFamily: 'Space Grotesk',
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      position.symbol,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: position.side,
                      backgroundColor: sideTint,
                      foregroundColor: sideColor,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${position.venue} · ${position.qty}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: appColors.subtleText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                position.value,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                position.pnl,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: pnlColor,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _parsePnl(String pnl) {
    final numeric = pnl.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(numeric) ?? 0;
  }
}
