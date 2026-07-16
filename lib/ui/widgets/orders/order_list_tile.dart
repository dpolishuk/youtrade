import 'package:flutter/material.dart';

import '../../../domain/entities/order.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'status_badge.dart';

/// Card-style tile for an open order.
class OrderListTile extends StatelessWidget {
  const OrderListTile({required this.order, this.onCancel, super.key});

  final Order order;
  final void Function(Order order)? onCancel;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final sideColor = order.isBuy ? appColors.bullish : appColors.bearish;
    final sideTint = sideColor.withValues(alpha: 0.16);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: appColors.foreground,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${order.type} · ${order.venue}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: appColors.tertiaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onCancel == null ? null : () => onCancel!(order),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: appColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Price ${order.price}',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: appColors.tertiaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  'Qty ${order.qty} · ${order.filled} filled',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: appColors.subtleText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
