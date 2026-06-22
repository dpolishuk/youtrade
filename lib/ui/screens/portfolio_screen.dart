import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/position.dart';
import '../../presentation/providers/portfolio_data_provider.dart';
import '../../presentation/theme/theme_extensions.dart';
import '../../presentation/theme/theme_mode.dart';
import '../../presentation/theme/theme_provider.dart';
import '../widgets/portfolio/allocation_bar.dart';
import '../widgets/portfolio/exchange_card.dart';
import '../widgets/portfolio/equity_curve.dart';
import '../widgets/portfolio/position_tile.dart';

/// The Portfolio/Home screen rendered from the YouTrade mockups.
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(themeSettingsProvider);
    final portfolio = ref.watch(portfolioDataProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, ref, settings),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 4,
                    bottom: 24,
                  ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeSettings settings,
  ) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final accent = appColors?.accent ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: CustomPaint(
              size: const Size(17, 17),
              painter: _CheckmarkPainter(color: Colors.white),
            ),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YouTrade',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  letterSpacing: -0.04 * 16,
                  height: 1,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                settings.visualDirection == AppVisualDirection.flux
                    ? 'Flux Terminal'
                    : 'Carbon Terminal',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'JetBrains Mono',
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.14 * 8.5,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          _IconButton(
            icon: Icons.dark_mode,
            onTap: () =>
                ref.read(themeSettingsProvider.notifier).toggleLightDark(),
            tooltip: 'Toggle theme',
          ),
          const SizedBox(width: 7),
          _DirectionButton(
            label: settings.visualDirection == AppVisualDirection.flux
                ? 'FLUX'
                : 'CARBON',
            onTap: () => ref
                .read(themeSettingsProvider.notifier)
                .toggleVisualDirection(),
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthLabel(BuildContext context, int venueCount) {
    return Text(
      'Aggregated net worth · $venueCount venues',
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
    final color = appColors?.bullish ?? Colors.green;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(Icons.arrow_upward, size: 13, color: color),
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
            '24h',
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
          'Allocation by venue',
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
              label: s.venue.displayName,
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
                  name: e.venue.displayName,
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
          'Open positions',
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

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: theme.dividerColor),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final accent = appColors?.accent ?? theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: theme.dividerColor),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                letterSpacing: 0.08 * 10,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.74)
      ..lineTo(size.width * 0.78, size.height * 0.28);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
