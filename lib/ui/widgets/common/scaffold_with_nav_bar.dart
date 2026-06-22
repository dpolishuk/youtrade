import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'demo_mode_banner.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _activeColor = Color(0xFF00E6D2);
  static const _inactiveColor = Color(0x57FFFFFF);
  static const _backgroundColor = Color(0xFF080B12);
  static const _borderColor = Color(0x12FFFFFF);

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const DemoModeBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _borderColor)),
        ),
        child: NavigationBar(
          backgroundColor: _backgroundColor,
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
              color: isSelected ? _activeColor : _inactiveColor,
            );
          }),
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: const [
            NavigationDestination(
              icon: Icon(
                Icons.pie_chart_outline,
                color: _inactiveColor,
                size: 22,
              ),
              selectedIcon: Icon(
                Icons.pie_chart,
                color: _activeColor,
                size: 22,
              ),
              label: 'Portfolio',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart, color: _inactiveColor, size: 22),
              selectedIcon: Icon(
                Icons.show_chart,
                color: _activeColor,
                size: 22,
              ),
              label: 'Markets',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.candlestick_chart_outlined,
                color: _inactiveColor,
                size: 22,
              ),
              selectedIcon: Icon(
                Icons.candlestick_chart,
                color: _activeColor,
                size: 22,
              ),
              label: 'Trade',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.view_list_outlined,
                color: _inactiveColor,
                size: 22,
              ),
              selectedIcon: Icon(
                Icons.view_list,
                color: _activeColor,
                size: 22,
              ),
              label: 'Options',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.grid_view_outlined,
                color: _inactiveColor,
                size: 22,
              ),
              selectedIcon: Icon(
                Icons.grid_view,
                color: _activeColor,
                size: 22,
              ),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
