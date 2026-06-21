import 'package:flutter/material.dart';

import '../../domain/entities/venue.dart';
import '../../presentation/theme/theme_extensions.dart';
import '../widgets/exchange_detail/api_status_banner.dart';
import '../widgets/exchange_detail/asset_balance_tile.dart';
import '../widgets/exchange_detail/balance_card.dart';
import '../widgets/exchange_detail/pnl_card.dart';
import '../widgets/exchange_detail/trade_history_list.dart';
import '../widgets/exchange_detail/venue_chip_row.dart';
import '../widgets/exchange_detail/venue_header.dart';
import '../widgets/exchange_detail/venue_style.dart';

class ExchangeDetailScreen extends StatelessWidget {
  const ExchangeDetailScreen({this.exchangeId = 'binance', super.key});

  final String exchangeId;

  Venue get _selectedVenue => _resolveVenue(exchangeId);
  static const _allocationPercent = 45.2;
  static const _kinds = 'Spot · Perp · Options';
  static const _balance = '\$312,480.00';
  static const _pnl = '+\$6,620.00';
  static const _pnlPercent = '+2.12%';
  static const _keyStatus = 'Read-only keys active';

  List<AssetBalance> get _assets => [
    AssetBalance(
      symbol: 'BTC',
      glyph: '₿',
      value: '\$158,400',
      share: 0.507,
      shareColor: venueColor(_selectedVenue),
    ),
    AssetBalance(
      symbol: 'ETH',
      glyph: 'Ξ',
      value: '\$37,120',
      share: 0.119,
      shareColor: venueColor(_selectedVenue),
    ),
    AssetBalance(
      symbol: 'USDT',
      glyph: '\$',
      value: '\$88,420',
      share: 0.283,
      shareColor: venueColor(_selectedVenue),
    ),
    AssetBalance(
      symbol: 'SOL',
      glyph: '◎',
      value: '\$28,540',
      share: 0.091,
      shareColor: venueColor(_selectedVenue),
    ),
  ];

  static final _trades = [
    const TradeHistoryItem(
      side: 'BUY',
      symbol: 'BTCUSDT',
      type: 'Limit',
      venue: 'Binance',
      time: '09:12',
      price: '\$58,400.0',
      quantity: '0.50 BTC',
    ),
    const TradeHistoryItem(
      side: 'SELL',
      symbol: 'ETHUSDT',
      type: 'Stop',
      venue: 'Binance',
      time: '08:47',
      price: '\$3,050.00',
      quantity: '8.0 ETH',
    ),
    const TradeHistoryItem(
      side: 'BUY',
      symbol: 'SOLUSDT',
      type: 'Limit',
      venue: 'Binance',
      time: '08:30',
      price: '\$150.00',
      quantity: '120 SOL',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final pnlColor = appColors?.bullish ?? Colors.green;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildBackButton(context),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VenueChipRow(
                        selectedVenue: _selectedVenue,
                        onVenueSelected: (_) {},
                      ),
                      const SizedBox(height: 16),
                      VenueHeader(
                        venue: _selectedVenue,
                        allocationPercent: _allocationPercent,
                        kinds: _kinds,
                      ),
                      const SizedBox(height: 14),
                      ApiStatusBanner(isLive: true, keyStatus: _keyStatus),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: BalanceCard(
                              label: 'Balance',
                              value: _balance,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PnlCard(
                              label: '24h P&L',
                              value: _pnl,
                              percent: _pnlPercent,
                              valueColor: pnlColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle(context, 'Balances'),
                      const SizedBox(height: 9),
                      _buildAssetList(context),
                      const SizedBox(height: 18),
                      _buildSectionTitle(context, 'Recent Trades'),
                      const SizedBox(height: 9),
                      TradeHistoryList(trades: _trades),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_ios,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                'All portfolios',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'Geist Mono',
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        fontFamily: 'Geist Mono',
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.1 * 9,
        fontSize: 9,
      ),
    );
  }

  Widget _buildAssetList(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: _assets
            .map((asset) => AssetBalanceTile(asset: asset))
            .toList(),
      ),
    );
  }
}

Venue _resolveVenue(String id) {
  return Venue.values.firstWhere(
    (venue) => venue.id == id,
    orElse: () => Venue.unknown,
  );
}
