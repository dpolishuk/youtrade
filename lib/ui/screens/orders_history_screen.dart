import 'package:flutter/material.dart';

import '../../data/datasources/mock/deterministic_market_data_store.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/position.dart';
import '../../presentation/theme/theme_extensions.dart';
import '../widgets/orders/history_order_tile.dart';
import '../widgets/orders/order_list_tile.dart';
import '../widgets/orders/position_list_tile.dart';

/// Orders & History screen with Open / History / Positions tabs.
class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({this.positions, super.key});

  final List<Position>? positions;

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  int _selectedIndex = 0;
  final _tabs = const ['Open', 'History', 'Positions'];

  late List<Order> _openOrders;

  @override
  void initState() {
    super.initState();
    _openOrders = List<Order>.from(DeterministicMarketDataStore.openOrders);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Orders',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.02 * 18,
                  color: appColors.foreground,
                ),
              ),
              const SizedBox(height: 14),
              _buildTabs(appColors),
              const SizedBox(height: 14),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(AppColorTheme appColors) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: appColors.borderSubtle)),
      ),
      child: Row(
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
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? appColors.foreground
                        : appColors.tertiaryText,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    return switch (_selectedIndex) {
      0 => _buildOpenList(),
      1 => _buildHistoryList(appColors),
      2 => _buildPositionsList(appColors),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildOpenList() {
    return ListView.separated(
      itemCount: _openOrders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (_, index) {
        final order = _openOrders[index];
        return OrderListTile(
          order: order,
          onCancel: (_) => setState(() => _openOrders.remove(order)),
        );
      },
    );
  }

  Widget _buildHistoryList(AppColorTheme appColors) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: ListView.separated(
        itemCount: DeterministicMarketDataStore.historyOrders.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: appColors.borderSubtle,
          indent: 14,
          endIndent: 14,
        ),
        itemBuilder: (_, index) => HistoryOrderTile(
          order: DeterministicMarketDataStore.historyOrders[index],
        ),
      ),
    );
  }

  Widget _buildPositionsList(AppColorTheme appColors) {
    final positions =
        widget.positions ?? DeterministicMarketDataStore.portfolioPositions;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: ListView.separated(
        itemCount: positions.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: appColors.borderSubtle,
          indent: 14,
          endIndent: 14,
        ),
        itemBuilder: (_, index) => PositionListTile(position: positions[index]),
      ),
    );
  }
}
