import 'package:flutter/material.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/position.dart';
import '../../presentation/theme/theme_extensions.dart';
import '../widgets/orders/history_order_tile.dart';
import '../widgets/orders/order_list_tile.dart';
import '../widgets/orders/position_list_tile.dart';

/// Orders & History screen with Open / History / Positions tabs.
class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  int _selectedIndex = 0;
  final _tabs = const ['Open', 'History', 'Positions'];

  final List<Order> _openOrders = const [
    Order(
      symbol: 'BTCUSDT',
      side: 'BUY',
      type: 'Limit',
      venue: 'Binance',
      price: '58,400.0',
      qty: '0.50',
      filled: '0%',
    ),
    Order(
      symbol: 'ETHUSDT',
      side: 'SELL',
      type: 'Stop',
      venue: 'Bybit',
      price: '3,050.00',
      qty: '8.0',
      filled: '0%',
    ),
    Order(
      symbol: 'SOLUSDT',
      side: 'BUY',
      type: 'Limit',
      venue: 'OKX',
      price: '150.00',
      qty: '120',
      filled: '34%',
    ),
    Order(
      symbol: 'AAPL',
      side: 'BUY',
      type: 'Limit',
      venue: 'Coinbase',
      price: '218.00',
      qty: '50',
      filled: '0%',
    ),
  ];

  final List<Order> _historyOrders = const [
    Order(
      symbol: 'BTCUSDT',
      side: 'BUY',
      type: 'Market',
      venue: 'Binance',
      price: '56,820.0',
      qty: '1.34',
      time: '09:12',
      status: 'Filled',
    ),
    Order(
      symbol: 'GC=F',
      side: 'SELL',
      type: 'Limit',
      venue: 'OKX',
      price: '2,640.0',
      qty: '4',
      time: '08:47',
      status: 'Filled',
    ),
    Order(
      symbol: 'ETHUSDT',
      side: 'BUY',
      type: 'Limit',
      venue: 'Bybit',
      price: '2,910.00',
      qty: '14.5',
      time: '08:30',
      status: 'Filled',
    ),
    Order(
      symbol: 'NVDA',
      side: 'SELL',
      type: 'Market',
      venue: 'Coinbase',
      price: '115.20',
      qty: '40',
      time: 'Yest',
      status: 'Filled',
    ),
    Order(
      symbol: 'SOLUSDT',
      side: 'BUY',
      type: 'Limit',
      venue: 'OKX',
      price: '162.40',
      qty: '60',
      time: 'Yest',
      status: 'Cancelled',
    ),
  ];

  final List<Position> _positions = const [
    Position(
      symbol: 'BTCUSDT',
      sym0: '฿',
      side: 'LONG',
      venue: 'Binance Perp',
      qty: '1.84 BTC',
      value: '\$107,320',
      pnl: '+\$4,210',
      tint: Color(0x24F7931A),
      iconColor: Color(0xFFF7931A),
    ),
    Position(
      symbol: 'ETHUSDT',
      sym0: 'Ξ',
      side: 'LONG',
      venue: 'Bybit Perp',
      qty: '22.5 ETH',
      value: '\$66,375',
      pnl: '-\$820',
      tint: Color(0x29627EEA),
      iconColor: Color(0xFF8B9CF0),
    ),
    Position(
      symbol: 'AAPL',
      sym0: 'A',
      side: 'LONG',
      venue: 'Coinbase',
      qty: '120 sh',
      value: '\$26,880',
      pnl: '+\$312',
      tint: Color(0x2900BBCC),
      iconColor: Color(0xFF00BBCC),
    ),
    Position(
      symbol: 'GC=F',
      sym0: 'Au',
      side: 'SHORT',
      venue: 'OKX Futures',
      qty: '4 lots',
      value: '\$31,200',
      pnl: '+\$680',
      tint: Color(0x29FFC457),
      iconColor: Color(0xFFFFC457),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Orders', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 14),
              _buildTabs(appColors),
              const SizedBox(height: 14),
              Expanded(child: _buildBody(theme, appColors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(AppColorTheme appColors) {
    return Row(
      children: List.generate(_tabs.length, (index) {
        final isSelected = index == _selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.only(bottom: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? appColors.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _tabs[index],
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : appColors.subtleText,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBody(ThemeData theme, AppColorTheme appColors) {
    return switch (_selectedIndex) {
      0 => _buildOpenList(),
      1 => _buildHistoryList(theme, appColors),
      2 => _buildPositionsList(theme, appColors),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildOpenList() {
    return ListView.separated(
      itemCount: _openOrders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (_, index) => OrderListTile(order: _openOrders[index]),
    );
  }

  Widget _buildHistoryList(ThemeData theme, AppColorTheme appColors) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: ListView.separated(
        itemCount: _historyOrders.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 14, endIndent: 14),
        itemBuilder: (_, index) =>
            HistoryOrderTile(order: _historyOrders[index]),
      ),
    );
  }

  Widget _buildPositionsList(ThemeData theme, AppColorTheme appColors) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: ListView.separated(
        itemCount: _positions.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 14, endIndent: 14),
        itemBuilder: (_, index) =>
            PositionListTile(position: _positions[index]),
      ),
    );
  }
}
