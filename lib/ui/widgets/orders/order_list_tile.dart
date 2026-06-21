import 'package:flutter/material.dart';

import '../../../domain/entities/order.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'status_badge.dart';

/// Card-style tile for an open order.
class OrderListTile extends StatelessWidget {
  const OrderListTile({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final sideColor = order.isBuy ? appColors.bullish : appColors.bearish;
    final sideTint = order.isBuy
        ? appColors.bullish.withValues(alpha: 0.16)
        : appColors.bearish.withValues(alpha: 0.16);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: order.side,
                backgroundColor: sideTint,
                foregroundColor: sideColor,
              ),
              const SizedBox(width: 8),
              Text(
                order.symbol,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${order.type} · ${order.venue}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: appColors.subtleText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Cancel',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: appColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price ${order.price}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: appColors.subtleText,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              Text(
                'Qty ${order.qty} · ${order.filled} filled',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: appColors.subtleText,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
