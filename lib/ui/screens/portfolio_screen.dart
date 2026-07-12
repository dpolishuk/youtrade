import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/position.dart';
import '../../presentation/providers/portfolio_data_provider.dart';
import '../../presentation/theme/theme_extensions.dart';
import '../widgets/portfolio/allocation_bar.dart';
import '../widgets/portfolio/exchange_card.dart';
import '../widgets/portfolio/equity_curve.dart';
import '../widgets/portfolio/position_tile.dart';

/// The Portfolio/Home screen rendered from live Bybit demo account data.
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncPortfolio = ref.watch(portfolioDataProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: asyncPortfolio.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _PortfolioError(
            message: error.toString(),
            onRetry: () => ref.invalidate(portfolioDataProvider),
          ),
          data: (portfolio) {
            if (portfolio.needsCredentials) {
              return const _ConnectApiKey();
            }
            return _PortfolioContent(portfolio: portfolio);
          },
        ),
      ),
    );
  }
}

class _PortfolioContent extends StatelessWidget {
  const _PortfolioContent({required this.portfolio});

  final PortfolioData portfolio;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNetWorthLabel(context, portfolio.venueCount),
            _buildTotalEquity(context, portfolio.netWorthFormatted),
            _buildDeltaRow(context, portfolio),
            const SizedBox(height: 14),
            EquityCurve(data: portfolio.equityCurve),
            const SizedBox(height: 18),
            _buildAllocationHeader(context, portfolio.assetMix),
            const SizedBox(height: 9),
            _buildAllocationBar(portfolio.allocationSegments),
            const SizedBox(height: 14),
            _buildExchangeCards(context, portfolio.exchanges),
            const SizedBox(height: 20),
            _buildPositionsHeader(context),
            const SizedBox(height: 9),
            _buildPositionsList(context, portfolio.positions),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthLabel(BuildContext context, int venueCount) {
    return Text(
      'Aggregated net worth · $venueCount venues'.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontFamily: 'JetBrains Mono',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.16 * 9.5,
        fontSize: 9.5,
      ),
    );
  }

  Widget _buildTotalEquity(BuildContext context, String formattedValue) {
    final theme = Theme.of(context);
    final parts = formattedValue.split('.');
    final whole = parts.first;
    final fraction = parts.length > 1 ? '.${parts.last}' : '.00';

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: whole,
              style: theme.textTheme.displaySmall?.copyWith(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w500,
                letterSpacing: -0.045 * 43,
                fontSize: 43,
                height: 0.95,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextSpan(
              text: fraction,
              style: theme.textTheme.displaySmall?.copyWith(
                fontFamily: 'Space Grotesk',
                fontSize: 18,
                color: theme.colorScheme.onSurfaceVariant,
                height: 0.95,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaRow(BuildContext context, PortfolioData portfolio) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final isPositive = portfolio.deltaAmount >= 0;
    final color = isPositive
        ? (appColors?.bullish ?? Colors.green)
        : (appColors?.bearish ?? Colors.red);
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            portfolio.deltaAmountFormatted,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            portfolio.deltaPercent,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'PnL',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationHeader(BuildContext context, String assetMix) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'ALLOCATION BY VENUE',
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: 'JetBrains Mono',
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.14 * 9.5,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            assetMix,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'JetBrains Mono',
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.06 * 9.5,
              fontSize: 9.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationBar(List<PortfolioAllocationSegment> segments) {
    return AllocationBar(
      segments: segments
          .map(
            (s) => AllocationSegment(
              label: s.label,
              color: s.color,
              share: s.share,
            ),
          )
          .toList(),
    );
  }

  Widget _buildExchangeCards(
    BuildContext context,
    List<PortfolioExchange> exchanges,
  ) {
    return Column(
      children: exchanges
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: ExchangeCard(
                data: ExchangeCardData(
                  name: e.name,
                  initial: e.initial,
                  kinds: e.kinds,
                  value: e.value,
                  percent: e.percentChange,
                  color: e.color,
                  tint: e.tint,
                ),
                onTap: () => context.push('/markets/exchange/${e.venue.id}'),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPositionsHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'OPEN POSITIONS',
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: 'JetBrains Mono',
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.14 * 9.5,
            fontSize: 9.5,
          ),
        ),
        TextButton(
          onPressed: () => context.push('/orders'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Orders →',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'JetBrains Mono',
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionsList(BuildContext context, List<Position> positions) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final bullish = appColors?.bullish ?? Colors.green;
    final bearish = appColors?.bearish ?? Colors.red;

    if (positions.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: theme.dividerColor),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No open positions',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'JetBrains Mono',
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: _separatedTiles(context, positions, bullish, bearish),
      ),
    );
  }

  List<Widget> _separatedTiles(
    BuildContext context,
    List<Position> positions,
    Color bullish,
    Color bearish,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < positions.length; i++) {
      final p = positions[i];
      final isLong = p.isLong;
      widgets.add(
        PositionTile(
          data: PositionTileData(
            symbol: p.symbol,
            symbolInitial: p.sym0,
            side: p.side,
            venue: p.venue,
            quantity: p.qty,
            value: p.value,
            pnl: p.pnl,
            pnlColor: p.pnl.startsWith('+') ? bullish : bearish,
            iconTint: p.tint,
            sideTint: isLong
                ? bullish.withValues(alpha: 0.16)
                : bearish.withValues(alpha: 0.16),
            sideColor: isLong ? bullish : bearish,
            iconColor: p.iconColor,
          ),
          onTap: () => context.push('/trading?symbol=${p.symbol}'),
        ),
      );
      if (i < positions.length - 1) {
        widgets.add(const Divider(height: 1, indent: 55));
      }
    }
    return widgets;
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
              'portfolio balance and positions.',
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

class _PortfolioError extends StatelessWidget {
  const _PortfolioError({required this.message, required this.onRetry});

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
              'Failed to load portfolio',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to fetch wallet balance from Bybit.',
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
