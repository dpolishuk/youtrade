import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/position.dart';
import '../../presentation/providers/orders_provider.dart';
import '../../presentation/providers/portfolio_data_provider.dart';
import '../../presentation/theme/theme_extensions.dart';
import '../widgets/orders/history_order_tile.dart';
import '../widgets/orders/order_list_tile.dart';
import '../widgets/orders/position_list_tile.dart';

/// Orders & History screen with Open / History / Positions tabs rendered from
/// real Bybit demo account data.
class OrdersHistoryScreen extends ConsumerStatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  ConsumerState<OrdersHistoryScreen> createState() =>
      _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends ConsumerState<OrdersHistoryScreen> {
  int _selectedIndex = 0;
  final _tabs = const ['Open', 'History', 'Positions'];

  /// Order IDs removed via the demo Cancel button (no real trade execution).
  final Set<String?> _cancelledOrderIds = {};

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final asyncOrders = ref.watch(ordersProvider);

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
              Expanded(
                child: asyncOrders.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _OrdersError(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(ordersProvider),
                  ),
                  data: (ordersData) {
                    if (ordersData.needsCredentials) {
                      return const _ConnectApiKey();
                    }
                    return _buildBody(appColors, ordersData);
                  },
                ),
              ),
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

  Widget _buildBody(AppColorTheme appColors, OrdersData ordersData) {
    return switch (_selectedIndex) {
      0 => _buildOpenList(appColors, ordersData.openOrders),
      1 => _buildHistoryList(appColors, ordersData.historyOrders),
      2 => _buildPositionsList(appColors),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildOpenList(AppColorTheme appColors, List<Order> openOrders) {
    final visible = openOrders
        .where((o) => !_cancelledOrderIds.contains(o.orderId))
        .toList();

    if (visible.isEmpty) {
      return _emptyState(appColors, 'No open orders');
    }

    return ListView.separated(
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (_, index) {
        final order = visible[index];
        return OrderListTile(
          order: order,
          onCancel: (_) =>
              setState(() => _cancelledOrderIds.add(order.orderId)),
        );
      },
    );
  }

  Widget _buildHistoryList(AppColorTheme appColors, List<Order> historyOrders) {
    if (historyOrders.isEmpty) {
      return _emptyState(appColors, 'No order history');
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: ListView.separated(
        itemCount: historyOrders.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: appColors.borderSubtle,
          indent: 14,
          endIndent: 14,
        ),
        itemBuilder: (_, index) =>
            HistoryOrderTile(order: historyOrders[index]),
      ),
    );
  }

  Widget _buildPositionsList(AppColorTheme appColors) {
    final asyncPortfolio = ref.watch(portfolioDataProvider);

    return asyncPortfolio.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _OrdersError(
        message: error.toString(),
        onRetry: () => ref.invalidate(portfolioDataProvider),
      ),
      data: (portfolio) {
        final positions = portfolio.positions;
        if (positions.isEmpty) {
          return _emptyState(appColors, 'No open positions');
        }
        return _positionsContainer(appColors, positions);
      },
    );
  }

  Widget _positionsContainer(
    AppColorTheme appColors,
    List<Position> positions,
  ) {
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

  Widget _emptyState(AppColorTheme appColors, String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          color: appColors.tertiaryText,
        ),
      ),
    );
  }
}

class _ConnectApiKey extends StatelessWidget {
  const _ConnectApiKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.key_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Connect API Key',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your Bybit demo account API credentials to view your '
              'open orders and trade history.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load orders',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to fetch orders from Bybit.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
