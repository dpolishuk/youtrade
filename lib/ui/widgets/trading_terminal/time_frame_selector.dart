import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/timeframe.dart';
import '../../../presentation/providers/trading_terminal_provider.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/theme/theme_extensions.dart';

class TimeFrameSelector extends ConsumerWidget {
  const TimeFrameSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradingTerminalProvider);
    final notifier = ref.read(tradingTerminalProvider.notifier);
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final accent = appColors.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tf in Timeframe.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: _TimeFrameChip(
                        label: tf.code.toUpperCase(),
                        isSelected: state.selectedTimeframe == tf,
                        onTap: () => notifier.selectTimeframe(tf),
                        accent: accent,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: appColors.chip,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: () => context.go('/markets/compare'),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 30,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: appColors.borderSubtle),
                ),
                child: Icon(Icons.stacked_line_chart, size: 15, color: accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeFrameChip extends StatelessWidget {
  const _TimeFrameChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final bg = isSelected ? accent.withValues(alpha: 0.15) : Colors.transparent;
    final border = isSelected
        ? accent.withValues(alpha: 0.4)
        : Colors.transparent;
    final fg = isSelected ? accent : appColors.tertiaryText;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: AppTheme.mono(
              color: fg,
              fontSize: 10.5,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
