import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/theme_extensions.dart';
import '../../../presentation/theme/theme_mode.dart';
import '../../../presentation/theme/theme_provider.dart';
import 'demo_mode_banner.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _darkBackgroundColor = Color(0xFF080B12);
  static const _darkBorderColor = Color(0x12FFFFFF);
  static const _darkInactiveColor = Color(0x57FFFFFF);

  static const _lightBackgroundColor = Color(0xFFFFFFFF);

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = appColors?.accent ?? const Color(0xFF00E6D2);
    final inactiveColor = isDark
        ? _darkInactiveColor
        : (appColors?.tertiaryText ?? const Color(0x61020D23));
    final backgroundColor = isDark
        ? _darkBackgroundColor
        : _lightBackgroundColor;
    final borderColor = isDark
        ? _darkBorderColor
        : (appColors?.borderSubtle ?? const Color(0x14020D23));

    final items = [
      _NavItemData(
        label: 'Portfolio',
        icon: Icons.pie_chart_outline,
        activeIcon: Icons.pie_chart,
      ),
      _NavItemData(
        label: 'Markets',
        icon: Icons.show_chart,
        activeIcon: Icons.show_chart,
      ),
      _NavItemData(
        label: 'Trade',
        icon: Icons.candlestick_chart_outlined,
        activeIcon: Icons.candlestick_chart,
      ),
      _NavItemData(
        label: 'Options',
        icon: Icons.view_list_outlined,
        activeIcon: Icons.view_list,
      ),
      _NavItemData(
        label: 'More',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
      ),
    ];

    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      body: Column(
        children: [
          const DemoModeBanner(),
          SafeArea(bottom: false, child: _AppHeader()),
          Expanded(
            child: MediaQuery(
              data: mediaQuery.copyWith(
                padding: mediaQuery.padding.copyWith(top: 0),
                viewPadding: mediaQuery.viewPadding.copyWith(top: 0),
              ),
              child: navigationShell,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        key: const Key('bottom-nav'),
        height: 74,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              _NavItem(
                key: Key('bottom-nav-item-$i'),
                index: i,
                selected: i == navigationShell.currentIndex,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                accentGlow: appColors!.accentGlow,
                data: items[i],
                onTap: () => _goBranch(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.accentGlow,
    required this.data,
    required this.onTap,
    super.key,
  });

  final int index;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final Color accentGlow;
  final _NavItemData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? data.activeIcon : data.icon,
              color: selected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              data.label,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.04 * 8.5,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Opacity(
              key: Key('bottom-nav-dot-$index'),
              opacity: selected ? 1.0 : 0.0,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accentGlow,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppHeader extends ConsumerWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final accent = appColors.accent;
    final settings = ref.watch(themeSettingsProvider);

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
                  color: appColors.foreground,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                settings.visualDirection == AppVisualDirection.flux
                    ? 'FLUX TERMINAL'
                    : 'CARBON TERMINAL',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'JetBrains Mono',
                  color: appColors.tertiaryText,
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
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final chipColor = appColors?.chip ?? theme.colorScheme.secondary;
    final iconColor =
        appColors?.subtleText ?? theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: theme.dividerColor),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: iconColor),
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
          color: appColors?.chip ?? theme.colorScheme.secondary,
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
