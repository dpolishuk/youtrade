import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/timeframe.dart';

/// Active side for the trade ticket.
enum OrderSide { buy, sell }

/// Active order type for the trade ticket.
enum OrderType { market, limit, stop }

/// Lower tabs on the Trading Terminal screen.
enum TerminalTab { trade, book, info, signals }

/// UI-only state for the Trading Terminal screen.
@immutable
class TradingTerminalState {
  const TradingTerminalState({
    this.selectedTab = TerminalTab.trade,
    this.orderSide = OrderSide.buy,
    this.orderType = OrderType.limit,
    this.leverage = 10,
    this.selectedSizePercent = 25,
    this.selectedTimeframe = Timeframe.h1,
  });

  final TerminalTab selectedTab;
  final OrderSide orderSide;
  final OrderType orderType;
  final int leverage;
  final int selectedSizePercent;
  final Timeframe selectedTimeframe;

  TradingTerminalState copyWith({
    TerminalTab? selectedTab,
    OrderSide? orderSide,
    OrderType? orderType,
    int? leverage,
    int? selectedSizePercent,
    Timeframe? selectedTimeframe,
  }) {
    return TradingTerminalState(
      selectedTab: selectedTab ?? this.selectedTab,
      orderSide: orderSide ?? this.orderSide,
      orderType: orderType ?? this.orderType,
      leverage: leverage ?? this.leverage,
      selectedSizePercent: selectedSizePercent ?? this.selectedSizePercent,
      selectedTimeframe: selectedTimeframe ?? this.selectedTimeframe,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradingTerminalState &&
          selectedTab == other.selectedTab &&
          orderSide == other.orderSide &&
          orderType == other.orderType &&
          leverage == other.leverage &&
          selectedSizePercent == other.selectedSizePercent &&
          selectedTimeframe == other.selectedTimeframe;

  @override
  int get hashCode => Object.hash(
    selectedTab,
    orderSide,
    orderType,
    leverage,
    selectedSizePercent,
    selectedTimeframe,
  );
}

/// Notifier that owns Trading Terminal UI state.
class TradingTerminalNotifier extends StateNotifier<TradingTerminalState> {
  TradingTerminalNotifier() : super(const TradingTerminalState());

  void selectTab(TerminalTab tab) {
    state = state.copyWith(selectedTab: tab);
  }

  void selectSide(OrderSide side) {
    state = state.copyWith(orderSide: side);
  }

  void selectOrderType(OrderType type) {
    state = state.copyWith(orderType: type);
  }

  void setLeverage(int leverage) {
    final clamped = leverage.clamp(1, 100);
    state = state.copyWith(leverage: clamped);
  }

  void selectSizePercent(int percent) {
    final clamped = percent.clamp(0, 100);
    state = state.copyWith(selectedSizePercent: clamped);
  }

  void selectTimeframe(Timeframe timeframe) {
    state = state.copyWith(selectedTimeframe: timeframe);
  }
}

/// Provider for the Trading Terminal UI state.
final tradingTerminalProvider =
    StateNotifierProvider<TradingTerminalNotifier, TradingTerminalState>(
      (ref) => TradingTerminalNotifier(),
    );
