import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/symbol_metadata.dart';
import '../../../domain/entities/ticker.dart';
import '../../../presentation/providers/trading_terminal_provider.dart';
import '../../../presentation/theme/app_theme.dart';
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

  static const _maxBaseSize = 4.2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradingTerminalProvider);
    final notifier = ref.read(tradingTerminalProvider.notifier);
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final meta = resolveSymbolMetadata(symbol);

    final price = tickerAsync.valueOrNull?.lastPrice ?? 0.0;
    final isBuy = state.orderSide == OrderSide.buy;
    final sideColor = isBuy ? appColors.bullish : appColors.bearish;
    final sizeQty = _maxBaseSize * state.selectedSizePercent / 100;
    final orderCost = sizeQty * price;

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
                    label: _orderTypeLabel(type),
                    isSelected: state.orderType == type,
                    onTap: () => notifier.selectOrderType(type),
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
            color: appColors.chip,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: appColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRICE',
                style: themeBodySmall(context)?.copyWith(
                  color: appColors.tertiaryText,
                  fontSize: 10,
                  letterSpacing: 0.06,
                ),
              ),
              Text(
                formatFixedPrice(price, meta.decimals),
                style: AppTheme.mono(
                  color: appColors.foreground,
                  fontSize: 14,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        if (meta.showsLeverage) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appColors.chip,
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
                      'LEVERAGE',
                      style: themeBodySmall(context)?.copyWith(
                        color: appColors.tertiaryText,
                        fontSize: 10,
                        letterSpacing: 0.06,
                      ),
                    ),
                    Text(
                      '${state.leverage}x',
                      style: AppTheme.mono(
                        color: appColors.accent,
                        fontSize: 13,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: state.leverage.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  activeColor: appColors.accent,
                  inactiveColor: appColors.borderSubtle,
                  onChanged: (value) => notifier.setLeverage(value.round()),
                ),
              ],
            ),
          ),
        ],
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
                    accent: appColors.accent,
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
                'ORDER SIZE',
                style: AppTheme.mono(
                  color: appColors.tertiaryText,
                  fontSize: 11,
                ),
              ),
              Text(
                '${sizeQty.toStringAsFixed(3)} ${meta.base} · \$${orderCost.toStringAsFixed(0)}',
                style: AppTheme.mono(color: appColors.foreground, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: sideColor.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: -6,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () =>
                _showDemoConfirmation(context, meta, isBuy, price, sizeQty),
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
              '${isBuy ? 'Buy / Long' : 'Sell / Short'} ${meta.base}',
              style: AppTheme.display(
                color: Colors.white,
                fontSize: 15,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  String _orderTypeLabel(OrderType type) => switch (type) {
    OrderType.limit => 'Limit',
    OrderType.market => 'Market',
    OrderType.stop => 'Stop',
  };

  void _showDemoConfirmation(
    BuildContext context,
    SymbolMetadata meta,
    bool isBuy,
    double price,
    double sizeQty,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final dialogTheme = Theme.of(context);
        final dialogColors = dialogTheme.extension<AppColorTheme>()!;
        return AlertDialog(
          backgroundColor: dialogTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: BorderSide(color: dialogColors.borderSubtle),
          ),
          title: Text(
            'Demo ${isBuy ? 'Buy' : 'Sell'}',
            style: AppTheme.display(
              color: dialogColors.foreground,
              fontSize: 18,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          content: Text(
            '${isBuy ? 'Buy' : 'Sell'} ${sizeQty.toStringAsFixed(3)} ${meta.base} @ ${formatFixedPrice(price, meta.decimals)}\n\nNo real order will be placed.',
            style: AppTheme.mono(color: dialogColors.subtleText, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: AppTheme.mono(
                  color: dialogColors.accent,
                  fontSize: 12,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

TextStyle? themeBodySmall(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall;

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
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    return Material(
      color: isActive ? color.withValues(alpha: 0.18) : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.6)
                  : appColors.borderSubtle,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTheme.display(
              color: isActive ? color : appColors.subtleText,
              fontSize: 14,
            ).copyWith(fontWeight: FontWeight.w600),
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
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return Material(
      color: isSelected ? appColors.foreground : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTheme.mono(
              color: isSelected
                  ? theme.colorScheme.surface
                  : appColors.subtleText,
              fontSize: 11,
            ).copyWith(fontWeight: FontWeight.w600),
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
    required this.accent,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    return Material(
      color: isSelected ? accent.withValues(alpha: 0.15) : appColors.chip,
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
              color: isSelected
                  ? accent.withValues(alpha: 0.4)
                  : appColors.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.mono(
              color: isSelected ? accent : appColors.subtleText,
              fontSize: 10.5,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
