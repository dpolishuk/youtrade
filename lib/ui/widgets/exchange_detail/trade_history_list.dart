import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class TradeHistoryItem {
  const TradeHistoryItem({
    required this.side,
    required this.symbol,
    required this.type,
    required this.venue,
    required this.time,
    required this.price,
    required this.quantity,
  });

  final String side;
  final String symbol;
  final String type;
  final String venue;
  final String time;
  final String price;
  final String quantity;
}

class TradeHistoryList extends StatelessWidget {
  const TradeHistoryList({required this.trades, super.key});

  final List<TradeHistoryItem> trades;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(children: _buildTiles(context)),
    );
  }

  List<Widget> _buildTiles(BuildContext context) {
    final tiles = <Widget>[];
    for (var i = 0; i < trades.length; i++) {
      tiles.add(TradeHistoryTile(trade: trades[i]));
      if (i < trades.length - 1) {
        tiles.add(const Divider(height: 1, indent: 14, endIndent: 14));
      }
    }
    return tiles;
  }
}

class TradeHistoryTile extends StatelessWidget {
  const TradeHistoryTile({required this.trade, super.key});

  final TradeHistoryItem trade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final isBuy = trade.side == 'BUY';
    final sideColor = isBuy
        ? appColors?.bullish ?? Colors.green
        : appColors?.bearish ?? Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: sideColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              trade.side,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'Geist Mono',
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06 * 8,
                fontSize: 8,
                color: sideColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trade.symbol,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${trade.type} · ${trade.venue} · ${trade.time}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'Geist Mono',
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trade.price,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFamily: 'Geist Mono',
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                trade.quantity,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'Geist Mono',
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
