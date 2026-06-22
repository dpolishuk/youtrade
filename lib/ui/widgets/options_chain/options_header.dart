import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class OptionsHeader extends StatelessWidget {
  const OptionsHeader({required this.symbol, required this.spot, super.key});

  final String symbol;
  final double spot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final foreground = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Row(
            children: [
              Text(
                symbol,
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: appColors.chip,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: appColors.borderSubtle),
                ),
                child: Text(
                  'OPTIONS',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
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
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 8.5,
                  letterSpacing: 0.06 * 8.5,
                  color: appColors.tertiaryText,
                ),
              ),
              Text(
                _formatPrice(spot),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: foreground,
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
