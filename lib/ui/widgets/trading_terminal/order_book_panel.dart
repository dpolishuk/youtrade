import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/order_book.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/symbol_metadata.dart';
import '../../../domain/entities/ticker.dart';
import '../../../presentation/providers/market_data_providers.dart';
import '../../../presentation/theme/app_theme.dart';
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

    return orderBookAsync.when(
      data: (book) =>
          _BookContent(book: book, tickerAsync: tickerAsync, symbol: symbol),
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
            style: themeBodySmall(context)?.copyWith(
              color: Theme.of(context).extension<AppColorTheme>()!.subtleText,
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
    required this.symbol,
  });

  final OrderBook book;
  final AsyncValue<Ticker> tickerAsync;
  final TradingSymbol symbol;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final meta = resolveSymbolMetadata(symbol);

    final price =
        tickerAsync.valueOrNull?.lastPrice ??
        (book.bestBid ?? 0) + (book.spread ?? 0) / 2;
    final bestBid = book.bestBid;
    final spread = book.spread ?? 0.0;
    final spreadPct = (bestBid != null && bestBid > 0)
        ? spread / bestBid * 100
        : 0.0;

    final visibleAsks = book.asks.take(6).toList().reversed.toList();
    final visibleBids = book.bids.take(6).toList();

    final askCum = _cumulative(visibleAsks);
    final bidCum = _cumulative(visibleBids);
    final dmax = askCum.isEmpty
        ? (bidCum.isEmpty ? 1.0 : bidCum.last)
        : bidCum.isEmpty
        ? askCum.last
        : max(askCum.last, bidCum.last);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price',
                style: AppTheme.mono(
                  color: appColors.tertiaryText,
                  fontSize: 8.5,
                ).copyWith(letterSpacing: 0.08),
              ),
              Text(
                'Size (${meta.base})',
                style: AppTheme.mono(
                  color: appColors.tertiaryText,
                  fontSize: 8.5,
                ).copyWith(letterSpacing: 0.08),
              ),
            ],
          ),
        ),
        _LevelList(
          levels: visibleAsks,
          cumulatives: askCum,
          color: appColors.bearish,
          barColor: appColors.bearish.withValues(alpha: 0.12),
          dmax: dmax,
          meta: meta,
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
                formatFixedPrice(price, meta.decimals),
                style: AppTheme.mono(
                  color: appColors.bullish,
                  fontSize: 15,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'spread ${formatFixedPrice(spread, meta.decimals)} · ${formatPercent(spreadPct)}',
                style: AppTheme.mono(
                  color: appColors.tertiaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        _LevelList(
          levels: visibleBids,
          cumulatives: bidCum,
          color: appColors.bullish,
          barColor: appColors.bullish.withValues(alpha: 0.12),
          dmax: dmax,
          meta: meta,
        ),
      ],
    );
  }

  List<double> _cumulative(List<OrderBookLevel> levels) {
    var sum = 0.0;
    return [for (final level in levels) sum += level.amount];
  }
}

class _LevelList extends StatelessWidget {
  const _LevelList({
    required this.levels,
    required this.cumulatives,
    required this.color,
    required this.barColor,
    required this.dmax,
    required this.meta,
  });

  final List<OrderBookLevel> levels;
  final List<double> cumulatives;
  final Color color;
  final Color barColor;
  final double dmax;
  final SymbolMetadata meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < levels.length; i++)
          _LevelRow(
            level: levels[i],
            cumulative: cumulatives[i],
            color: color,
            barColor: barColor,
            dmax: dmax,
            meta: meta,
          ),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.cumulative,
    required this.color,
    required this.barColor,
    required this.dmax,
    required this.meta,
  });

  final OrderBookLevel level;
  final double cumulative;
  final Color color;
  final Color barColor;
  final double dmax;
  final SymbolMetadata meta;

  @override
  Widget build(BuildContext context) {
    final depth = dmax > 0 ? cumulative / dmax : 0.0;
    final appColors = Theme.of(context).extension<AppColorTheme>()!;

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
                formatFixedPrice(level.price, meta.decimals),
                style: AppTheme.mono(
                  color: color,
                  fontSize: 11,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                level.amount.toStringAsFixed(3),
                style: AppTheme.mono(color: appColors.subtleText, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

TextStyle? themeBodySmall(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall;
