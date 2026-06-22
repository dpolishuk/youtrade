import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/exchange_balance.dart';
import '../../domain/entities/venue.dart';
import '../../presentation/providers/exchange_detail_provider.dart';
import '../../presentation/theme/theme_extensions.dart';
import '../widgets/exchange_detail/asset_balance_tile.dart';
import '../widgets/exchange_detail/balance_card.dart';
import '../widgets/exchange_detail/pnl_card.dart';
import '../widgets/exchange_detail/venue_chip_row.dart';
import '../widgets/exchange_detail/venue_header.dart';

class ExchangeDetailScreen extends ConsumerStatefulWidget {
  const ExchangeDetailScreen({this.exchangeId = 'binance', super.key});

  final String exchangeId;

  @override
  ConsumerState<ExchangeDetailScreen> createState() =>
      _ExchangeDetailScreenState();
}

class _ExchangeDetailScreenState extends ConsumerState<ExchangeDetailScreen> {
  late Venue _selectedVenue;

  @override
  void initState() {
    super.initState();
    _selectedVenue = _resolveVenue(widget.exchangeId);
  }

  @override
  void didUpdateWidget(covariant ExchangeDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exchangeId != oldWidget.exchangeId) {
      setState(() => _selectedVenue = _resolveVenue(widget.exchangeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final snapshot = ref.watch(exchangeDetailProvider(_selectedVenue));
    final upColor = appColors?.bullish ?? Colors.green;

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
                        onVenueSelected: (venue) =>
                            setState(() => _selectedVenue = venue),
                      ),
                      const SizedBox(height: 16),
                      VenueHeader(
                        venue: _selectedVenue,
                        kinds: snapshot.kinds,
                        accent: appColors?.accent ?? theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: BalanceCard(
                              label: 'Balance',
                              value: snapshot.total,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PnlCard(
                              label: '24h P&L',
                              value: snapshot.pnl,
                              percent: snapshot.pnlPercent,
                              valueColor: snapshot.pnl.startsWith('-')
                                  ? appColors?.bearish ?? Colors.red
                                  : upColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle(context, 'Balances'),
                      const SizedBox(height: 9),
                      _buildAssetList(context, snapshot.assets),
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
    final appColors = theme.extension<AppColorTheme>();
    final fg3 = appColors?.tertiaryText ?? theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left, size: 13, color: fg3),
            const SizedBox(width: 5),
            Text(
              'All portfolios',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'JetBrains Mono',
                color: fg3,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();

    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        fontFamily: 'JetBrains Mono',
        color: appColors?.tertiaryText ?? theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.1 * 9,
        fontSize: 9,
      ),
    );
  }

  Widget _buildAssetList(BuildContext context, List<ExchangeBalance> assets) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: appColors?.borderSubtle ?? theme.dividerColor,
        ),
      ),
      child: Column(
        children: assets
            .map((asset) => AssetBalanceTile(asset: asset))
            .toList(),
      ),
    );
  }
}

Venue _resolveVenue(String id) {
  return Venue.values.firstWhere(
    (venue) => venue.id == id,
    orElse: () => Venue.binance,
  );
}
