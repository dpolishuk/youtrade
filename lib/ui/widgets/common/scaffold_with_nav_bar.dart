import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/theme_extensions.dart';
import 'demo_mode_banner.dart';

class ScaffoldWithNavBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
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

    return Scaffold(
      body: Column(
        children: [
          const DemoModeBanner(),
          Expanded(child: navigationShell),
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
    required this.data,
    required this.onTap,
    super.key,
  });

  final int index;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
