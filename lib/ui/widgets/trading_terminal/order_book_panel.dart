import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/order_book.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/ticker.dart';
import '../../../presentation/providers/market_data_providers.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'formatting.dart';

class OrderBookPanel extends ConsumerWidget {
  const OrderBookPanel({
    required this.symbol,
    required this.tickerAsync,
    super.key,
  });

  final TradingSymbol symbol;
  final AsyncValue<Ticker> tickerAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderBookAsync = ref.watch(orderBookStreamProvider(symbol));
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return orderBookAsync.when(
      data: (book) => _BookContent(
        book: book,
        tickerAsync: tickerAsync,
        appColors: appColors,
        theme: theme,
        symbol: symbol,
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Order book unavailable',
            style: theme.textTheme.bodySmall?.copyWith(
              color: appColors.subtleText,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookContent extends StatelessWidget {
  const _BookContent({
    required this.book,
    required this.tickerAsync,
    required this.appColors,
    required this.theme,
    required this.symbol,
  });

  final OrderBook book;
  final AsyncValue<Ticker> tickerAsync;
  final AppColorTheme appColors;
  final ThemeData theme;
  final TradingSymbol symbol;

  @override
  Widget build(BuildContext context) {
    final price =
        tickerAsync.valueOrNull?.lastPrice ??
        (book.bestBid ?? 0) + (book.spread ?? 0) / 2;
    final bestBid = book.bestBid;
    final spread = book.spread ?? 0.0;
    final spreadPct = (bestBid != null && bestBid > 0)
        ? spread / bestBid * 100
        : 0.0;

    final visibleAsks = book.asks.take(6).toList();
    final visibleBids = book.bids.take(6).toList();
    final maxAmount = [
      ...visibleAsks.map((l) => l.amount),
      ...visibleBids.map((l) => l.amount),
    ].fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: appColors.subtleText,
                  letterSpacing: 0.08,
                ),
              ),
              Text(
                'Size (${symbol.base})',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: appColors.subtleText,
                  letterSpacing: 0.08,
                ),
              ),
            ],
          ),
        ),
        _LevelList(
          levels: visibleAsks,
          color: appColors.bearish,
          barColor: appColors.bearish.withValues(alpha: 0.18),
          maxAmount: maxAmount,
          theme: theme,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: appColors.borderSubtle),
              bottom: BorderSide(color: appColors.borderSubtle),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatPrice(price, maxDecimals: 2),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: appColors.bullish,
                ),
              ),
              Text(
                'spread ${formatPrice(spread, maxDecimals: 2)} · ${formatPercent(spreadPct)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: appColors.subtleText,
                ),
              ),
            ],
          ),
        ),
        _LevelList(
          levels: visibleBids,
          color: appColors.bullish,
          barColor: appColors.bullish.withValues(alpha: 0.18),
          maxAmount: maxAmount,
          theme: theme,
        ),
      ],
    );
  }
}

class _LevelList extends StatelessWidget {
  const _LevelList({
    required this.levels,
    required this.color,
    required this.barColor,
    required this.maxAmount,
    required this.theme,
  });

  final List<OrderBookLevel> levels;
  final Color color;
  final Color barColor;
  final double maxAmount;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final level in levels)
          _LevelRow(
            level: level,
            color: color,
            barColor: barColor,
            maxAmount: maxAmount,
            theme: theme,
          ),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.color,
    required this.barColor,
    required this.maxAmount,
    required this.theme,
  });

  final OrderBookLevel level;
  final Color color;
  final Color barColor;
  final double maxAmount;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final depth = maxAmount > 0 ? level.amount / maxAmount : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: depth,
              child: Container(color: barColor),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatPrice(level.price, maxDecimals: 2),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                level.amount.toStringAsFixed(4),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
