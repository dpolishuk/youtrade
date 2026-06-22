import 'package:flutter/material.dart';

import '../../../domain/entities/order.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'status_badge.dart';

/// Row-style tile for a historical order.
class HistoryOrderTile extends StatelessWidget {
  const HistoryOrderTile({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final sideColor = order.isBuy ? appColors.bullish : appColors.bearish;
    final sideTint = sideColor.withValues(alpha: 0.16);
    final statusColor = _statusColor(order.status, appColors);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          StatusBadge(
            label: order.side,
            backgroundColor: sideTint,
            foregroundColor: sideColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.symbol,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: appColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.type} · ${order.venue} · ${order.time}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
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
                order.price,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: appColors.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${order.qty} · ${order.status}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 9.5,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status, AppColorTheme appColors) {
    if (status == null) return appColors.subtleText;
    if (status == 'Filled') return appColors.subtleText;
    if (status == 'Cancelled') return appColors.tertiaryText;
    return appColors.bullish;
  }
}
