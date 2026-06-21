import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class ApiStatusBanner extends StatelessWidget {
  const ApiStatusBanner({
    required this.isLive,
    required this.keyStatus,
    super.key,
  });

  final bool isLive;
  final String keyStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final liveColor = appColors?.bullish ?? Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isLive ? liveColor : appColors?.subtleText,
              shape: BoxShape.circle,
              boxShadow: isLive
                  ? [
                      BoxShadow(
                        color: liveColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isLive ? 'API LIVE' : 'API OFFLINE',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'Geist Mono',
              color: isLive ? liveColor : appColors?.subtleText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06 * 9,
            ),
          ),
          const Spacer(),
          Text(
            keyStatus,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'Geist Mono',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
