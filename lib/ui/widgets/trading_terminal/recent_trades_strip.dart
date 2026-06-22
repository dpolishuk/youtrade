import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/trade.dart';
import '../../../presentation/providers/market_data_providers.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'formatting.dart';

class RecentTradesStrip extends ConsumerWidget {
  const RecentTradesStrip({required this.symbol, super.key});

  final TradingSymbol symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(tradesStreamProvider(symbol));
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return tradesAsync.when(
      data: (trades) {
        final recent =
            (trades.toList()
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp)))
                .take(5)
                .toList();
        if (recent.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent trades',
              style: theme.textTheme.labelSmall?.copyWith(
                color: appColors.subtleText,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: appColors.borderSubtle),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < recent.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: i < recent.length - 1
                              ? BorderSide(color: appColors.borderSubtle)
                              : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            recent[i].side.name.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: recent[i].side == TradeSide.buy
                                  ? appColors.bullish
                                  : appColors.bearish,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formatPrice(recent[i].price, maxDecimals: 2),
                            style: theme.textTheme.labelMedium,
                          ),
                          Text(
                            recent[i].amount.toStringAsFixed(4),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: appColors.subtleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const Center(child: Text('Trades unavailable')),
    );
  }
}
