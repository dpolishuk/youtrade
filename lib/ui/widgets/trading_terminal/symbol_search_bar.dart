import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/symbol_metadata.dart';
import '../../../domain/entities/venue.dart';
import '../../../presentation/providers/market_screener_provider.dart';
import '../../../presentation/providers/selected_symbol_provider.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'formatting.dart';

class SymbolSearchBar extends ConsumerStatefulWidget {
  const SymbolSearchBar({super.key});

  @override
  ConsumerState<SymbolSearchBar> createState() => _SymbolSearchBarState();
}

class _SymbolSearchBarState extends ConsumerState<SymbolSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  double _fieldWidth = 0;

  static const _maxResults = 20;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _overlayEntry?.markNeedsBuild();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final renderBox = context.findRenderObject() as RenderBox;
    _fieldWidth = renderBox.size.width;
    _overlayEntry = OverlayEntry(builder: _buildDropdown);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectItem(MarketScreenerItem item) {
    ref.read(selectedSymbolProvider.notifier).state = TradingSymbol(
      base: item.symbol,
      quote: 'USDT',
      venue: Venue.bybit,
      rawSymbol: item.rawSymbol,
    );
    _removeOverlay();
    _controller.clear();
    _focusNode.unfocus();
  }

  List<MarketScreenerItem> _filterItems(List<MarketScreenerItem> items) {
    final query = _controller.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? items
        : items
              .where(
                (item) =>
                    item.symbol.toLowerCase().contains(query) ||
                    item.rawSymbol.toLowerCase().contains(query),
              )
              .toList();
    return filtered.take(_maxResults).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenerAsync = ref.watch(marketScreenerItemsProvider);
    final selected = ref.watch(selectedSymbolProvider);
    final appColors = Theme.of(context).extension<AppColorTheme>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          key: const ValueKey('symbol_search_field'),
          controller: _controller,
          focusNode: _focusNode,
          style: AppTheme.mono(color: appColors.foreground, fontSize: 13),
          decoration: InputDecoration(
            hintText: chipLabel(selected.rawSymbol),
            hintStyle: AppTheme.mono(
              color: appColors.subtleText,
              fontSize: 13,
            ).copyWith(fontWeight: FontWeight.w600),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            prefixIcon: _buildPrefixIcon(screenerAsync, appColors),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: appColors.accent, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildPrefixIcon(
    AsyncValue<List<MarketScreenerItem>> async,
    AppColorTheme appColors,
  ) {
    if (async.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: appColors.subtleText,
          ),
        ),
      );
    }
    if (async.hasError) {
      return IconButton(
        key: const ValueKey('symbol_search_error_retry'),
        icon: Icon(Icons.error_outline, color: appColors.bearish, size: 18),
        onPressed: () => ref.invalidate(marketScreenerItemsProvider),
      );
    }
    return Icon(Icons.search, color: appColors.subtleText, size: 18);
  }

  Widget _buildDropdown(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final items =
        ref.read(marketScreenerItemsProvider).valueOrNull ??
        const <MarketScreenerItem>[];
    final filtered = _filterItems(items);

    return CompositedTransformFollower(
      link: _layerLink,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 4),
      child: SizedBox(
        width: max(_fieldWidth, 200),
        child: Material(
          color: Theme.of(context).cardColor,
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No symbols found',
                    style: AppTheme.mono(
                      color: appColors.subtleText,
                      fontSize: 12,
                    ),
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    key: const ValueKey('symbol_search_dropdown'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in filtered)
                          _SearchResultTile(
                            key: ValueKey('search_result_${item.rawSymbol}'),
                            item: item,
                            appColors: appColors,
                            onTap: () => _selectItem(item),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    super.key,
    required this.item,
    required this.appColors,
    required this.onTap,
  });

  final MarketScreenerItem item;
  final AppColorTheme appColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPositive = item.change24hPercent >= 0;
    final changeColor = isPositive ? appColors.bullish : appColors.bearish;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.symbol,
                    style: AppTheme.mono(
                      color: appColors.foreground,
                      fontSize: 13,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    item.rawSymbol,
                    style: AppTheme.mono(
                      color: appColors.subtleText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatFixedPrice(item.price, item.priceDecimals),
              style: AppTheme.mono(color: appColors.foreground, fontSize: 12),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 64,
              child: Text(
                formatPercent(item.change24hPercent),
                textAlign: TextAlign.end,
                style: AppTheme.mono(
                  color: changeColor,
                  fontSize: 11,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
