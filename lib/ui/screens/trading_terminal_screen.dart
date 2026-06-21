import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/candle.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/entities/ticker.dart';
import '../../presentation/providers/market_data_providers.dart';
import '../../presentation/providers/selected_symbol_provider.dart';
import '../../presentation/providers/trading_terminal_provider.dart';
import '../widgets/trading_terminal/candlestick_chart.dart';
import '../widgets/trading_terminal/fundamentals_card.dart';
import '../widgets/trading_terminal/lower_tabs.dart';
import '../widgets/trading_terminal/order_book_panel.dart';
import '../widgets/trading_terminal/recent_trades_strip.dart';
import '../widgets/trading_terminal/signal_gauge.dart';
import '../widgets/trading_terminal/symbol_chip_row.dart';
import '../widgets/trading_terminal/symbol_header.dart';
import '../widgets/trading_terminal/time_frame_selector.dart';
import '../widgets/trading_terminal/trade_ticket.dart';

class TradingTerminalScreen extends ConsumerWidget {
  const TradingTerminalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(selectedSymbolProvider);
    final tickerAsync = ref.watch(tickerStreamProvider(symbol));
    final candlesAsync = ref.watch(candlesProvider(symbol));
    final tab = ref.watch(tradingTerminalProvider).selectedTab;

    return Scaffold(
      appBar: AppBar(title: const Text('Terminal')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const SymbolChipRow(),
              const SizedBox(height: 12),
              SymbolHeader(
                symbol: symbol,
                tickerAsync: tickerAsync,
                candlesAsync: candlesAsync,
              ),
              const TimeFrameSelector(),
              CandlestickChart(symbol: symbol),
              const SizedBox(height: 14),
              const LowerTabs(),
              _ActivePanel(
                symbol: symbol,
                tickerAsync: tickerAsync,
                candlesAsync: candlesAsync,
                tab: tab,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePanel extends StatelessWidget {
  const _ActivePanel({
    required this.symbol,
    required this.tickerAsync,
    required this.candlesAsync,
    required this.tab,
  });

  final TradingSymbol symbol;
  final AsyncValue<Ticker> tickerAsync;
  final AsyncValue<List<Candle>> candlesAsync;
  final TerminalTab tab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: switch (tab) {
        TerminalTab.trade => _TradeTab(
          symbol: symbol,
          tickerAsync: tickerAsync,
        ),
        TerminalTab.book => OrderBookPanel(
          symbol: symbol,
          tickerAsync: tickerAsync,
        ),
        TerminalTab.info => FundamentalsCard(
          symbol: symbol,
          ticker: tickerAsync.valueOrNull,
          candles: candlesAsync.valueOrNull ?? const <Candle>[],
        ),
        TerminalTab.signals => SignalGauge(
          symbol: symbol,
          ticker: tickerAsync.valueOrNull,
          candles: candlesAsync.valueOrNull ?? const <Candle>[],
        ),
      },
    );
  }
}

class _TradeTab extends StatelessWidget {
  const _TradeTab({required this.symbol, required this.tickerAsync});

  final TradingSymbol symbol;
  final AsyncValue<Ticker> tickerAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TradeTicket(symbol: symbol, tickerAsync: tickerAsync),
        const SizedBox(height: 16),
        RecentTradesStrip(symbol: symbol),
      ],
    );
  }
}
