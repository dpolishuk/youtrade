import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/trading_terminal_provider.dart';
import '../../../presentation/theme/theme_extensions.dart';

class LowerTabs extends ConsumerWidget {
  const LowerTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradingTerminalProvider);
    final notifier = ref.read(tradingTerminalProvider.notifier);
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    final tabs = [
      _TabData(label: 'Trade', value: TerminalTab.trade),
      _TabData(label: 'Book', value: TerminalTab.book),
      _TabData(label: 'Info', value: TerminalTab.info),
      _TabData(label: 'Signals', value: TerminalTab.signals),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: _TabButton(
                label: tab.label,
                isSelected: state.selectedTab == tab.value,
                onTap: () => notifier.selectTab(tab.value),
                colorScheme: theme.colorScheme,
                appColors: appColors,
              ),
            ),
        ],
      ),
    );
  }
}

class _TabData {
  const _TabData({required this.label, required this.value});

  final String label;
  final TerminalTab value;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.appColors,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final AppColorTheme appColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? colorScheme.primary : appColors.subtleText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
