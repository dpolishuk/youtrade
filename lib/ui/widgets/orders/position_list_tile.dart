import 'package:flutter/material.dart';

import '../../../domain/entities/position.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'status_badge.dart';

/// Row-style tile for an open position.
class PositionListTile extends StatelessWidget {
  const PositionListTile({required this.position, this.onTap, super.key});

  final Position position;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final sideColor = position.isLong ? appColors.bullish : appColors.bearish;
    final sideTint = sideColor.withValues(alpha: 0.16);
    final pnlColor = _parsePnl(position.pnl) >= 0
        ? appColors.bullish
        : appColors.bearish;

    return InkWell(
      onTap: onTap,
      child: Padding(
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
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: position.iconColor,
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: appColors.foreground,
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
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9.5,
                      color: appColors.tertiaryText,
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
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: appColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  position.pnl,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: pnlColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _parsePnl(String pnl) {
    final numeric = pnl.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(numeric) ?? 0;
  }
}
