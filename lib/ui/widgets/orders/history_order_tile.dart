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
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final sideColor = order.isBuy ? appColors.bullish : appColors.bearish;
    final sideTint = order.isBuy
        ? appColors.bullish.withValues(alpha: 0.16)
        : appColors.bearish.withValues(alpha: 0.16);
    final statusColor = _statusColor(order.status, appColors, theme);

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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.type} · ${order.venue} · ${order.time}',
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
                order.price,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${order.qty} · ${order.status}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status, AppColorTheme appColors, ThemeData theme) {
    if (status == null) return appColors.subtleText;
    if (status == 'Filled') return appColors.subtleText;
    if (status == 'Cancelled') return theme.colorScheme.onSurfaceVariant;
    return appColors.bullish;
  }
}
