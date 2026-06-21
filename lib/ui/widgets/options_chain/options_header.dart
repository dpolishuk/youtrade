import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class OptionsHeader extends StatelessWidget {
  const OptionsHeader({required this.spot, super.key});

  final double spot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: Row(
        children: [
          Row(
            children: [
              Text(
                'BTC',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.02 * 18,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: appColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: appColors.borderSubtle),
                ),
                child: Text(
                  'OPTIONS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06 * 8,
                    color: appColors.subtleText,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Spot',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 8.5,
                  letterSpacing: 0.06 * 8.5,
                  color: appColors.subtleText,
                ),
              ),
              Text(
                _formatPrice(spot),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Geist',
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0);
    return formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
