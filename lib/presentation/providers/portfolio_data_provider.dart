import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mock/deterministic_market_data_store.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/venue.dart';
import '../theme/theme_extensions.dart';
import '../theme/theme_provider.dart';

/// An exchange allocation displayed on the Portfolio screen.
@immutable
class PortfolioExchange {
  const PortfolioExchange({
    required this.venue,
    required this.initial,
    required this.kinds,
    required this.value,
    required this.percentChange,
    required this.color,
    required this.tint,
  });

  final Venue venue;
  final String initial;
  final String kinds;
  final String value;
  final double percentChange;
  final Color color;
  final Color tint;
}

/// A single allocation segment for the venue allocation bar.
@immutable
class PortfolioAllocationSegment {
  const PortfolioAllocationSegment({
    required this.venue,
    required this.color,
    required this.share,
  });

  final Venue venue;
  final Color color;
  final double share;
}

/// All deterministic data needed to render the Portfolio screen.
@immutable
class PortfolioData {
  const PortfolioData({
    required this.netWorth,
    required this.netWorthFormatted,
    required this.deltaAmount,
    required this.deltaAmountFormatted,
    required this.deltaPercent,
    required this.venueCount,
    required this.assetMix,
    required this.equityCurve,
    required this.allocationSegments,
    required this.exchanges,
    required this.positions,
  });

  final double netWorth;
  final String netWorthFormatted;
  final double deltaAmount;
  final String deltaAmountFormatted;
  final String deltaPercent;
  final int venueCount;
  final String assetMix;
  final List<double> equityCurve;
  final List<PortfolioAllocationSegment> allocationSegments;
  final List<PortfolioExchange> exchanges;
  final List<Position> positions;
}

/// Formats a USD amount with comma separators and two decimal places.
String _formatCurrency(double value) {
  final isNegative = value < 0;
  final abs = value.abs();
  final whole = abs.truncate();
  final cents = ((abs - whole) * 100).round().toString().padLeft(2, '0');
  final wholeFormatted = _addCommas(whole);
  return '${isNegative ? '-' : ''}\$$wholeFormatted.$cents';
}

String _formatCompact(double value) {
  final isNegative = value < 0;
  final abs = value.abs();
  final whole = abs.truncate();
  final wholeFormatted = _addCommas(whole);
  return '${isNegative ? '-' : ''}\$$wholeFormatted';
}

String _addCommas(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}

/// Provider that exposes the deterministic Portfolio screen data.
final portfolioDataProvider = Provider<PortfolioData>((ref) {
  final appColors = ref.watch(appColorThemeProvider);
  final accent = appColors.accent;

  final exchanges = <PortfolioExchange>[];
  final allocationSegments = <PortfolioAllocationSegment>[];

  for (final venue in [Venue.binance, Venue.bybit, Venue.okx, Venue.coinbase]) {
    final exchange = DeterministicMarketDataStore.portfolioExchanges[venue]!;
    final allocation = DeterministicMarketDataStore.portfolioAllocation[venue]!;
    final color = venue == Venue.okx ? accent : allocation.color;
    final tint = venue == Venue.okx
        ? accent.withValues(alpha: 0.16)
        : allocation.tint;

    exchanges.add(
      PortfolioExchange(
        venue: venue,
        initial: _initialFor(venue),
        kinds: _kindsFor(venue),
        value: _formatCompact(exchange.value),
        percentChange: exchange.percentChange,
        color: color,
        tint: tint,
      ),
    );

    allocationSegments.add(
      PortfolioAllocationSegment(
        venue: venue,
        color: color,
        share: allocation.share,
      ),
    );
  }

  return PortfolioData(
    netWorth: DeterministicMarketDataStore.portfolioNetWorth,
    netWorthFormatted: _formatCurrency(
      DeterministicMarketDataStore.portfolioNetWorth,
    ),
    deltaAmount: DeterministicMarketDataStore.portfolio24hDelta,
    deltaAmountFormatted:
        '+${_formatCurrency(DeterministicMarketDataStore.portfolio24hDelta)}',
    deltaPercent: DeterministicMarketDataStore.portfolio24hDeltaPct,
    venueCount: exchanges.length,
    assetMix: DeterministicMarketDataStore.portfolioAssetMix,
    equityCurve: DeterministicMarketDataStore.equityCurve,
    allocationSegments: allocationSegments,
    exchanges: exchanges,
    positions: DeterministicMarketDataStore.portfolioPositions,
  );
});

/// Provider that exposes the resolved [AppColorTheme] for the current theme.
final appColorThemeProvider = Provider<AppColorTheme>((ref) {
  final theme = ref.watch(appThemeProvider);
  return theme.extension<AppColorTheme>()!;
});

String _initialFor(Venue venue) {
  return switch (venue) {
    Venue.binance => 'B',
    Venue.bybit => 'Y',
    Venue.okx => 'O',
    Venue.coinbase => 'C',
    Venue.unknown => '?',
  };
}

String _kindsFor(Venue venue) {
  return switch (venue) {
    Venue.binance => 'Spot · Perp · Options',
    Venue.bybit => 'Perp · Spot',
    Venue.okx => 'Spot · Perp · Options',
    Venue.coinbase => 'Spot · Stocks',
    Venue.unknown => '',
  };
}
