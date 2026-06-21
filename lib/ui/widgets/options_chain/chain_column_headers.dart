import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class ChainColumnHeaders extends StatelessWidget {
  const ChainColumnHeaders({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 8,
      letterSpacing: 0.08 * 8,
      color: appColors.subtleText,
      fontFamily: 'Geist',
      fontWeight: FontWeight.w500,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Calls',
                  style: headerStyle?.copyWith(color: appColors.bullish),
                ),
              ),
              Expanded(
                child: Text(
                  'Strike',
                  textAlign: TextAlign.center,
                  style: headerStyle,
                ),
              ),
              Expanded(
                child: Text(
                  'Puts',
                  textAlign: TextAlign.right,
                  style: headerStyle?.copyWith(color: appColors.bearish),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('IV', style: headerStyle)),
              Expanded(flex: 2, child: Text('Δ', style: headerStyle)),
              Expanded(
                flex: 3,
                child: Text(
                  'Mark',
                  textAlign: TextAlign.right,
                  style: headerStyle,
                ),
              ),
              const Spacer(flex: 2),
              Expanded(flex: 3, child: Text('Mark', style: headerStyle)),
              Expanded(
                flex: 2,
                child: Text(
                  'Δ',
                  textAlign: TextAlign.right,
                  style: headerStyle,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'IV',
                  textAlign: TextAlign.right,
                  style: headerStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
