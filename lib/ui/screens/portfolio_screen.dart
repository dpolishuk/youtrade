import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final appColors = theme.extension<AppColorTheme>();
    final settings = ref.watch(themeSettingsProvider);

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
                      _buildNetWorthLabel(context),
                      _buildTotalEquity(context),
                      _buildDeltaRow(context, appColors),
                      const SizedBox(height: 14),
                      const EquityCurve(),
                      const SizedBox(height: 18),
                      _buildAllocationHeader(context),
                      const SizedBox(height: 9),
                      _buildAllocationBar(),
                      const SizedBox(height: 14),
                      _buildExchangeCards(context),
                      const SizedBox(height: 20),
                      _buildPositionsHeader(context),
                      const SizedBox(height: 9),
                      _buildPositionsList(context),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: appColors?.accent ?? theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: (appColors?.accent ?? theme.colorScheme.primary)
                      .withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.trending_up, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YouTrade',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.04 * 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                settings.visualDirection == AppVisualDirection.flux
                    ? 'Flux Terminal'
                    : 'Carbon Terminal',
                style: theme.textTheme.labelSmall?.copyWith(
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

  Widget _buildNetWorthLabel(BuildContext context) {
    return Text(
      'Aggregated net worth · 3 venues',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.16 * 9.5,
        fontSize: 9.5,
      ),
    );
  }

  Widget _buildTotalEquity(BuildContext context) {
    final theme = Theme.of(context);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '\$124,350',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.045 * 43,
                fontSize: 43,
                height: 0.95,
                fontFamily: 'Space Grotesk',
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextSpan(
              text: '.42',
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 18,
                color: theme.colorScheme.onSurfaceVariant,
                height: 0.95,
                fontFamily: 'Space Grotesk',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaRow(BuildContext context, AppColorTheme? appColors) {
    final theme = Theme.of(context);
    final color = appColors?.bullish ?? Colors.green;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(Icons.arrow_upward, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            '+\$1,284.50',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist Mono',
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+1.04%',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist Mono',
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '24h',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'Geist Mono',
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Allocation by venue',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.14 * 9.5,
            fontSize: 9.5,
          ),
        ),
        Text(
          'Mixed assets',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.06 * 9.5,
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationBar() {
    return const AllocationBar(
      segments: [
        AllocationSegment(
          label: 'Binance',
          color: Color(0xFFF0B90B),
          share: 45,
        ),
        AllocationSegment(label: 'Bybit', color: Color(0xFFFFC107), share: 30),
        AllocationSegment(
          label: 'Coinbase',
          color: Color(0xFF0052FF),
          share: 25,
        ),
      ],
    );
  }

  Widget _buildExchangeCards(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final accent = appColors?.accent ?? theme.colorScheme.primary;

    final exchanges = [
      ExchangeCardData(
        name: 'Binance',
        initial: 'B',
        kinds: 'SPOT · PERPS · OPTIONS',
        value: '\$55,957.69',
        percent: 1.24,
        color: const Color(0xFFF0B90B),
        tint: const Color(0x26F0B90B),
      ),
      ExchangeCardData(
        name: 'Bybit',
        initial: 'Y',
        kinds: 'PERPS · SPOT',
        value: '\$37,305.13',
        percent: -0.38,
        color: accent,
        tint: accent.withValues(alpha: 0.15),
      ),
      ExchangeCardData(
        name: 'Coinbase',
        initial: 'C',
        kinds: 'SPOT',
        value: '\$31,087.60',
        percent: 0.72,
        color: const Color(0xFF0052FF),
        tint: const Color(0x260052FF),
      ),
    ];

    return Column(
      children: exchanges
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: ExchangeCard(data: e),
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
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.14 * 9.5,
            fontSize: 9.5,
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Orders →',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionsList(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final bullish = appColors?.bullish ?? Colors.green;
    final bearish = appColors?.bearish ?? Colors.red;

    final positions = [
      PositionTileData(
        symbol: 'BTC',
        symbolInitial: '₿',
        side: 'LONG',
        venue: 'Binance',
        quantity: '0.42 BTC',
        value: '\$28,420.00',
        pnl: '+\$840.50',
        pnlColor: bullish,
        iconTint: const Color(0xFFF7931A),
        sideTint: bullish.withValues(alpha: 0.15),
        sideColor: bullish,
      ),
      PositionTileData(
        symbol: 'ETH',
        symbolInitial: 'Ξ',
        side: 'LONG',
        venue: 'Bybit',
        quantity: '4.20 ETH',
        value: '\$12,610.00',
        pnl: '-\$210.30',
        pnlColor: bearish,
        iconTint: const Color(0xFF627EEA),
        sideTint: bullish.withValues(alpha: 0.15),
        sideColor: bullish,
      ),
      PositionTileData(
        symbol: 'SOL',
        symbolInitial: 'S',
        side: 'SHORT',
        venue: 'Binance',
        quantity: '120 SOL',
        value: '\$14,760.00',
        pnl: '+\$305.20',
        pnlColor: bullish,
        iconTint: const Color(0xFF14F195),
        sideTint: bearish.withValues(alpha: 0.15),
        sideColor: bearish,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(children: _separatedTiles(positions)),
    );
  }

  List<Widget> _separatedTiles(List<PositionTileData> positions) {
    final widgets = <Widget>[];
    for (var i = 0; i < positions.length; i++) {
      widgets.add(PositionTile(data: positions[i]));
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
                fontFamily: 'Geist Mono',
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
