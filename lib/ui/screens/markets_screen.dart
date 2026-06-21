import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/market_screener_provider.dart';
import '../../presentation/theme/theme_extensions.dart';
import '../widgets/markets/filter_chips.dart';
import '../widgets/markets/market_list_tile.dart';

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
    final markets = ref.watch(filteredMarketScreenerItemsProvider);

    ref.listen(marketScreenerSearchProvider, (previous, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
        _searchController.selection = TextSelection.collapsed(
          offset: next.length,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Markets'), centerTitle: false),
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
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: appColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 15, color: appColors.subtleText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('markets_search_field'),
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search symbols, venues, assets',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: appColors.subtleText,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
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
              const FilterChips(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Symbol',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8.5,
                        letterSpacing: 0.08 * 8.5,
                        color: appColors.subtleText,
                        fontFamily: 'Geist',
                      ),
                    ),
                    Text(
                      'Last · 24h',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8.5,
                        letterSpacing: 0.08 * 8.5,
                        color: appColors.subtleText,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: appColors.borderSubtle),
                  ),
                  child: markets.isEmpty
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
