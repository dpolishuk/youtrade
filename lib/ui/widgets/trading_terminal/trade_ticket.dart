import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/ticker.dart';
import '../../../presentation/providers/trading_terminal_provider.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'formatting.dart';

class TradeTicket extends ConsumerWidget {
  const TradeTicket({
    required this.symbol,
    required this.tickerAsync,
    super.key,
  });

  final TradingSymbol symbol;
  final AsyncValue<Ticker> tickerAsync;

  static const _maxBaseSize = 1.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradingTerminalProvider);
    final notifier = ref.read(tradingTerminalProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColorTheme>()!;

    final price = tickerAsync.valueOrNull?.lastPrice ?? 0.0;
    final isBuy = state.orderSide == OrderSide.buy;
    final sideColor = isBuy ? appColors.bullish : appColors.bearish;
    final sizeQty = _maxBaseSize * state.selectedSizePercent / 100;
    final orderCost = price * sizeQty / state.leverage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _SideButton(
                label: 'Buy / Long',
                isActive: isBuy,
                color: appColors.bullish,
                onTap: () => notifier.selectSide(OrderSide.buy),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SideButton(
                label: 'Sell / Short',
                isActive: !isBuy,
                color: appColors.bearish,
                onTap: () => notifier.selectSide(OrderSide.sell),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final type in OrderType.values)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type == OrderType.values.last ? 0 : 4,
                  ),
                  child: _OrderTypeChip(
                    label: type.name.toUpperCase(),
                    isSelected: state.orderType == type,
                    onTap: () => notifier.selectOrderType(type),
                    colorScheme: colorScheme,
                    appColors: appColors,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: appColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: appColors.subtleText,
                ),
              ),
              Text(
                formatPrice(price, maxDecimals: 2),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: appColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Leverage',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: appColors.subtleText,
                    ),
                  ),
                  Text(
                    '${state.leverage}x',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: state.leverage.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                activeColor: colorScheme.primary,
                inactiveColor: appColors.borderSubtle,
                onChanged: (value) => notifier.setLeverage(value.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final pct in const [25, 50, 75, 100])
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: pct == 100 ? 0 : 4),
                  child: _SizePercentChip(
                    label: '$pct%',
                    isSelected: state.selectedSizePercent == pct,
                    onTap: () => notifier.selectSizePercent(pct),
                    colorScheme: colorScheme,
                    appColors: appColors,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order size',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: appColors.subtleText,
                ),
              ),
              Text(
                '${sizeQty.toStringAsFixed(4)} ${symbol.base} · ${formatPrice(orderCost, maxDecimals: 2)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            // Order submission is not wired in this UI-only task.
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: sideColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: Text(
            isBuy ? 'Buy / Long ${symbol.base}' : 'Sell / Short ${symbol.base}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isActive ? color : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isActive ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderTypeChip extends StatelessWidget {
  const _OrderTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.appColors,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final AppColorTheme appColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? colorScheme.primary : appColors.surfaceGlass,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SizePercentChip extends StatelessWidget {
  const _SizePercentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.appColors,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final AppColorTheme appColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? colorScheme.primary : colorScheme.surface,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? colorScheme.primary : appColors.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
