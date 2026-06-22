import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/trading_terminal_provider.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/theme/theme_extensions.dart';

class LowerTabs extends ConsumerWidget {
  const LowerTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradingTerminalProvider);
    final notifier = ref.read(tradingTerminalProvider.notifier);

    const tabs = [
      _TabData(label: 'Trade', value: TerminalTab.trade),
      _TabData(label: 'Book', value: TerminalTab.book),
      _TabData(label: 'Info', value: TerminalTab.info),
      _TabData(label: 'Signals', value: TerminalTab.signals),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: _TabButton(
                label: tab.label,
                isSelected: state.selectedTab == tab.value,
                onTap: () => notifier.selectTab(tab.value),
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
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? appColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.mono(
            color: isSelected
                ? const Color(0xFFF2F5FA)
                : const Color(0x57FFFFFF),
            fontSize: 11,
          ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.03),
        ),
      ),
    );
  }
}
