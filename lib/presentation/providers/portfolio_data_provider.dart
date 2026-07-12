import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bybit_config.dart';
import '../../core/formatting.dart';
import '../../core/result.dart';
import '../../data/datasources/mock/deterministic_market_data_store.dart';
import '../../data/datasources/remote/bybit/bybit_account_client.dart';
import '../../domain/entities/account_position.dart';
import '../../domain/entities/account_wallet_balance.dart';
import '../../domain/entities/position.dart';
import '../../domain/entities/venue.dart';
import '../theme/theme_extensions.dart';
import '../theme/theme_provider.dart';

/// An exchange allocation displayed on the Portfolio screen.
@immutable
class PortfolioExchange {
  const PortfolioExchange({
    required this.venue,
    required this.name,
    required this.initial,
    required this.kinds,
    required this.value,
    required this.percentChange,
    required this.color,
    required this.tint,
  });

  final Venue venue;
  final String name;
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
    required this.label,
    required this.color,
    required this.share,
  });

  final String label;
  final Color color;
  final double share;
}

/// All data needed to render the Portfolio screen.
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
    this.needsCredentials = false,
  });

  /// Sentinel PortfolioData used when API credentials are not configured.
  factory PortfolioData.needsCredentials() => PortfolioData(
    needsCredentials: true,
    netWorth: 0,
    netWorthFormatted: r'$0.00',
    deltaAmount: 0,
    deltaAmountFormatted: r'+$0.00',
    deltaPercent: '+0.00%',
    venueCount: 0,
    assetMix: '',
    equityCurve: const [],
    allocationSegments: const [],
    exchanges: const [],
    positions: const [],
  );

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
  final bool needsCredentials;
}

/// Extracts the base asset from a trading-pair symbol (e.g. `BTCUSDT` -> `BTC`).
String baseAsset(String symbol) {
  for (final quote in const ['USDT', 'USDC', 'USD']) {
    if (symbol.endsWith(quote)) {
      return symbol.substring(0, symbol.length - quote.length);
    }
  }
  return symbol;
}

/// Maps a [WalletBalance] and list of [AccountPosition]s into [PortfolioData]
/// using [accent] for directional colors.
PortfolioData buildPortfolioData({
  required WalletBalance wallet,
  required List<AccountPosition> positions,
  required Color accent,
}) {
  final totalEquity = wallet.totalEquity;
  final totalPnl = positions.fold(0.0, (sum, p) => sum + p.unrealisedPnl);

  final exchanges = <PortfolioExchange>[];
  final allocationSegments = <PortfolioAllocationSegment>[];

  for (final coin in wallet.coins) {
    final share = totalEquity > 0 ? (coin.equity / totalEquity) * 100 : 0.0;
    final tint = accent.withValues(alpha: 0.16);
    exchanges.add(
      PortfolioExchange(
        venue: Venue.bybit,
        name: coin.coin,
        initial: coin.coin.isNotEmpty ? coin.coin[0] : '?',
        kinds: 'Bybit Wallet',
        value: formatCompactMoney(coin.equity),
        percentChange: 0,
        color: accent,
        tint: tint,
      ),
    );
    allocationSegments.add(
      PortfolioAllocationSegment(label: coin.coin, color: accent, share: share),
    );
  }

  final positionEntities = positions.map((p) {
    final base = baseAsset(p.symbol);
    final isLong = p.isLong;
    final pnlAbs = p.unrealisedPnl.abs();
    final pnlSign = p.unrealisedPnl >= 0 ? '+' : '-';
    return Position(
      symbol: p.symbol,
      sym0: base.isNotEmpty ? base[0] : '?',
      side: isLong ? 'LONG' : 'SHORT',
      venue: 'Bybit Perp',
      qty: '${p.size.toStringAsFixed(p.size >= 1 ? 2 : 4)} $base',
      value: formatCurrency(p.unrealisedPnl),
      pnl: '$pnlSign${formatCurrency(pnlAbs)}',
      tint: accent.withValues(alpha: 0.16),
      iconColor: accent,
    );
  }).toList();

  final deltaSign = totalPnl >= 0 ? '+' : '-';
  final deltaPercent = totalEquity > 0
      ? '$deltaSign${(totalPnl.abs() / totalEquity * 100).toStringAsFixed(2)}%'
      : '+0.00%';

  return PortfolioData(
    netWorth: totalEquity,
    netWorthFormatted: formatCurrency(totalEquity),
    deltaAmount: totalPnl,
    deltaAmountFormatted: '$deltaSign${formatCurrency(totalPnl.abs())}',
    deltaPercent: deltaPercent,
    venueCount: wallet.coins.length,
    assetMix: wallet.coins.map((c) => c.coin).join(' · '),
    equityCurve: DeterministicMarketDataStore.equityCurve,
    allocationSegments: allocationSegments,
    exchanges: exchanges,
    positions: positionEntities,
  );
}

/// Provides the [BybitAccountClient] used by the portfolio. Override in tests
/// to inject a mock client.
final bybitAccountClientProvider = Provider<BybitAccountClient>((ref) {
  final client = BybitAccountClient();
  ref.onDispose(client.close);
  return client;
});

/// Whether Bybit API credentials are configured. Override in tests.
final bybitHasCredentialsProvider = Provider<bool>(
  (ref) => BybitConfig.hasCredentials,
);

/// Provider that exposes the Portfolio screen data from the real Bybit demo
/// account wallet balance and positions.
///
/// When credentials are missing ([bybitHasCredentialsProvider] is false) the
/// returned [PortfolioData] has [PortfolioData.needsCredentials] set to true so
/// the screen can render a "Connect API key" state.
final portfolioDataProvider = FutureProvider<PortfolioData>((ref) async {
  if (!ref.watch(bybitHasCredentialsProvider)) {
    return PortfolioData.needsCredentials();
  }

  final appColors = ref.watch(appColorThemeProvider);
  final accent = appColors.accent;
  final client = ref.watch(bybitAccountClientProvider);

  final walletResult = await client.getWalletBalance();
  final wallet = switch (walletResult) {
    Success(value: final w) => w,
    Err(failure: final f) => throw Exception(f.message),
  };

  final positionsResult = await client.getPositions();
  final positions = positionsResult.fold<List<AccountPosition>>(
    (_) => const [],
    (p) => p,
  );

  return buildPortfolioData(
    wallet: wallet,
    positions: positions,
    accent: accent,
  );
});

/// Provider that exposes the resolved [AppColorTheme] for the current theme.
final appColorThemeProvider = Provider<AppColorTheme>((ref) {
  final theme = ref.watch(appThemeProvider);
  return theme.extension<AppColorTheme>()!;
});
