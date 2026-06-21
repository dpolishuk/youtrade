import 'package:flutter/material.dart';

/// Data model for an open position tile.
@immutable
class PositionTileData {
  const PositionTileData({
    required this.symbol,
    required this.symbolInitial,
    required this.side,
    required this.venue,
    required this.quantity,
    required this.value,
    required this.pnl,
    required this.pnlColor,
    required this.iconTint,
    required this.sideTint,
    required this.sideColor,
    this.iconColor = Colors.white,
  });

  final String symbol;
  final String symbolInitial;
  final String side;
  final String venue;
  final String quantity;
  final String value;
  final String pnl;
  final Color pnlColor;
  final Color iconTint;
  final Color sideTint;
  final Color sideColor;
  final Color iconColor;
}

/// Tile displaying a single open position.
class PositionTile extends StatelessWidget {
  const PositionTile({required this.data, this.onTap, super.key});

  final PositionTileData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                color: data.iconTint,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                data.symbolInitial,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: data.iconColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
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
                        data.symbol,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: data.sideTint,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          data.side,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: data.sideColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 8,
                            letterSpacing: 0.06 * 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${data.venue} · ${data.quantity}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist Mono',
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.pnl,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist Mono',
                    fontSize: 10.5,
                    color: data.pnlColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
