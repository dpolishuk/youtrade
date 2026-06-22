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

    return Scaffold(
      body: Column(
        children: [
          const DemoModeBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: NavigationBar(
          backgroundColor: backgroundColor,
          indicatorColor: Colors.transparent,
          elevation: 0,
          height: 74,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.04 * 8.5,
              color: isSelected ? activeColor : inactiveColor,
            );
          }),
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.pie_chart_outline,
                color: inactiveColor,
                size: 22,
              ),
              selectedIcon: Icon(Icons.pie_chart, color: activeColor, size: 22),
              label: 'Portfolio',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart, color: inactiveColor, size: 22),
              selectedIcon: Icon(
                Icons.show_chart,
                color: activeColor,
                size: 22,
              ),
              label: 'Markets',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.candlestick_chart_outlined,
                color: inactiveColor,
                size: 22,
              ),
              selectedIcon: Icon(
                Icons.candlestick_chart,
                color: activeColor,
                size: 22,
              ),
              label: 'Trade',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.view_list_outlined,
                color: inactiveColor,
                size: 22,
              ),
              selectedIcon: Icon(Icons.view_list, color: activeColor, size: 22),
              label: 'Options',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.grid_view_outlined,
                color: inactiveColor,
                size: 22,
              ),
              selectedIcon: Icon(Icons.grid_view, color: activeColor, size: 22),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
