import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/timeframe.dart';
import '../../../presentation/providers/trading_terminal_provider.dart';
import '../../../presentation/theme/theme_extensions.dart';

class TimeFrameSelector extends ConsumerWidget {
  const TimeFrameSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradingTerminalProvider);
    final notifier = ref.read(tradingTerminalProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.extension<AppColorTheme>()!;

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
                        label: tf.code,
                        isSelected: state.selectedTimeframe == tf,
                        onTap: () => notifier.selectTimeframe(tf),
                        colorScheme: colorScheme,
                        appColors: appColors,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: () {
                // Compare action is not part of this task.
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 30,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: appColors.borderSubtle),
                ),
                child: Icon(
                  Icons.stacked_line_chart,
                  size: 15,
                  color: colorScheme.primary,
                ),
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

    return Material(
      color: isSelected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isSelected ? colorScheme.primary : appColors.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
