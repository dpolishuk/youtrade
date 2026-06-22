import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/candle.dart';
import '../../domain/entities/symbol.dart';
import '../../domain/entities/ticker.dart';
import '../../domain/entities/venue.dart';
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

class TradingTerminalScreen extends ConsumerStatefulWidget {
  const TradingTerminalScreen({this.symbol, super.key});

  final String? symbol;

  @override
  ConsumerState<TradingTerminalScreen> createState() =>
      _TradingTerminalScreenState();
}

class _TradingTerminalScreenState extends ConsumerState<TradingTerminalScreen> {
  static final _symbolPartRegex = RegExp(r'^[A-Za-z0-9.]{1,20}$');
  bool _invalidSymbolWarningShown = false;

  @override
  void didUpdateWidget(covariant TradingTerminalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.symbol != oldWidget.symbol) {
      _invalidSymbolWarningShown = false;
    }
  }

  TradingSymbol _resolveSymbol() {
    final raw = widget.symbol?.trim();
    if (raw != null && raw.isNotEmpty && _symbolPartRegex.hasMatch(raw)) {
      return TradingSymbol(base: raw, quote: 'USDT', venue: Venue.binance);
    }

    if (raw != null && !_invalidSymbolWarningShown) {
      _invalidSymbolWarningShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid symbol parameter: $raw')),
        );
      });
    }

    return ref.watch(selectedSymbolProvider);
  }

  @override
  Widget build(BuildContext context) {
    final selectedSymbol = _resolveSymbol();
    final terminalState = ref.watch(tradingTerminalProvider);
    final tickerAsync = ref.watch(tickerStreamProvider(selectedSymbol));
    final candlesAsync = ref.watch(
      candlesProvider((selectedSymbol, terminalState.selectedTimeframe)),
    );
    final tab = terminalState.selectedTab;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const SymbolChipRow(),
              const SizedBox(height: 12),
              SymbolHeader(
                symbol: selectedSymbol,
                tickerAsync: tickerAsync,
                candlesAsync: candlesAsync,
              ),
              const TimeFrameSelector(),
              CandlestickChart(
                candles: candlesAsync.valueOrNull ?? const <Candle>[],
              ),
              const SizedBox(height: 14),
              const LowerTabs(),
              _ActivePanel(
                symbol: selectedSymbol,
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
