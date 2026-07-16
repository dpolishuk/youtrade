import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/presentation/providers/trading_terminal_provider.dart';

void main() {
  group('TradingTerminalNotifier', () {
    ProviderContainer makeContainer() => ProviderContainer();

    test('initial state uses defaults', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(tradingTerminalProvider);
      expect(state.selectedTab, TerminalTab.trade);
      expect(state.orderSide, OrderSide.buy);
      expect(state.orderType, OrderType.limit);
      expect(state.leverage, 10);
      expect(state.selectedSizePercent, 25);
      expect(state.selectedTimeframe, Timeframe.h1);
    });

    test('selectTab updates the selected tab', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container
          .read(tradingTerminalProvider.notifier)
          .selectTab(TerminalTab.signals);

      expect(
        container.read(tradingTerminalProvider).selectedTab,
        TerminalTab.signals,
      );
    });

    test('selectSide updates the order side', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container
          .read(tradingTerminalProvider.notifier)
          .selectSide(OrderSide.sell);

      expect(container.read(tradingTerminalProvider).orderSide, OrderSide.sell);
    });

    group('selectOrderType', () {
      test('selects limit order type', () {
        final container = makeContainer();
        addTearDown(container.dispose);

        container
            .read(tradingTerminalProvider.notifier)
            .selectOrderType(OrderType.limit);

        expect(
          container.read(tradingTerminalProvider).orderType,
          OrderType.limit,
        );
      });

      test('selects stop order type', () {
        final container = makeContainer();
        addTearDown(container.dispose);

        container
            .read(tradingTerminalProvider.notifier)
            .selectOrderType(OrderType.stop);

        expect(
          container.read(tradingTerminalProvider).orderType,
          OrderType.stop,
        );
      });

      test('selects market order type', () {
        final container = makeContainer();
        addTearDown(container.dispose);

        container
            .read(tradingTerminalProvider.notifier)
            .selectOrderType(OrderType.market);

        expect(
          container.read(tradingTerminalProvider).orderType,
          OrderType.market,
        );
      });
    });

    group('setLeverage', () {
      test('clamps leverage to a minimum of 1', () {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(tradingTerminalProvider.notifier).setLeverage(0);

        expect(container.read(tradingTerminalProvider).leverage, 1);
      });

      test('clamps leverage to a maximum of 100', () {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(tradingTerminalProvider.notifier).setLeverage(200);

        expect(container.read(tradingTerminalProvider).leverage, 100);
      });

      test('keeps leverage inside the valid range', () {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(tradingTerminalProvider.notifier).setLeverage(50);

        expect(container.read(tradingTerminalProvider).leverage, 50);
      });
    });

    group('selectSizePercent', () {
      test('clamps size percent to a minimum of 0', () {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(tradingTerminalProvider.notifier).selectSizePercent(-10);

        expect(container.read(tradingTerminalProvider).selectedSizePercent, 0);
      });

      test('clamps size percent to a maximum of 100', () {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(tradingTerminalProvider.notifier).selectSizePercent(150);

        expect(
          container.read(tradingTerminalProvider).selectedSizePercent,
          100,
        );
      });

      test('keeps size percent inside the valid range', () {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(tradingTerminalProvider.notifier).selectSizePercent(75);

        expect(container.read(tradingTerminalProvider).selectedSizePercent, 75);
      });
    });

    test('selectTimeframe updates the selected timeframe', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container
          .read(tradingTerminalProvider.notifier)
          .selectTimeframe(Timeframe.h4);

      expect(
        container.read(tradingTerminalProvider).selectedTimeframe,
        Timeframe.h4,
      );
    });
  });
}
