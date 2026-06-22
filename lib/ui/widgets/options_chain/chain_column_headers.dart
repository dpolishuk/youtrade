import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class ChainColumnHeaders extends StatelessWidget {
  const ChainColumnHeaders({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorTheme>()!;
    final headerStyle = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 8,
      letterSpacing: 0.08 * 8,
      color: appColors.tertiaryText,
      fontWeight: FontWeight.w500,
    );
    final subHeaderStyle = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 7.5,
      letterSpacing: 0.04 * 7.5,
      color: appColors.tertiaryText,
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
                  style: headerStyle.copyWith(color: appColors.bullish),
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
                  style: headerStyle.copyWith(color: appColors.bearish),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
          child: Row(
            children: [
              Expanded(child: Text('IV', style: subHeaderStyle)),
              Expanded(child: Text('Δ', style: subHeaderStyle)),
              Expanded(
                child: Text(
                  'Mark',
                  textAlign: TextAlign.right,
                  style: subHeaderStyle,
                ),
              ),
              Expanded(child: const SizedBox.shrink()),
              Expanded(child: Text('Mark', style: subHeaderStyle)),
              Expanded(
                child: Text(
                  'Δ',
                  textAlign: TextAlign.right,
                  style: subHeaderStyle,
                ),
              ),
              Expanded(
                child: Text(
                  'IV',
                  textAlign: TextAlign.right,
                  style: subHeaderStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
