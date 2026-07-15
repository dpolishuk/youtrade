import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/market_screener_provider.dart';
import '../../presentation/theme/theme_extensions.dart';
import '../widgets/markets/filter_chips.dart';
import '../widgets/markets/market_list_tile.dart';
import '../widgets/markets/sort_dropdown.dart';

class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key});

  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final asyncMarkets = ref.watch(filteredMarketScreenerItemsProvider);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.34);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: appColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 15, color: mutedColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('markets_search_field'),
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search symbols, venues, assets',
                          hintStyle: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 13,
                            color: mutedColor,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                        onChanged: (value) {
                          ref
                                  .read(marketScreenerSearchProvider.notifier)
                                  .state =
                              value;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(child: FilterChips()),
                  SizedBox(width: 8),
                  SortDropdown(),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SYMBOL',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 8.5,
                        letterSpacing: 0.08 * 8.5,
                        color: mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'LAST · 24H',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 8.5,
                        letterSpacing: 0.08 * 8.5,
                        color: mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: appColors.borderSubtle),
                  ),
                  child: asyncMarkets.when(
                    data: (markets) => markets.isEmpty
                        ? Center(
                            child: Text(
                              'No markets found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: appColors.subtleText,
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: ListView.builder(
                              itemCount: markets.length,
                              itemBuilder: (context, index) {
                                return MarketListTile(market: markets[index]);
                              },
                            ),
                          ),
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onSurface,
                        strokeWidth: 2,
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: appColors.bearish,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load markets',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: appColors.subtleText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              ref.invalidate(marketScreenerItemsProvider);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
