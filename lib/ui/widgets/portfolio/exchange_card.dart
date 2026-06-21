import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

/// Data model for an exchange card shown on the portfolio screen.
@immutable
class ExchangeCardData {
  const ExchangeCardData({
    required this.name,
    required this.initial,
    required this.kinds,
    required this.value,
    required this.percent,
    required this.color,
    required this.tint,
    this.isLive = true,
  });

  final String name;
  final String initial;
  final String kinds;
  final String value;
  final double percent;
  final Color color;
  final Color tint;
  final bool isLive;
}

/// Card displaying a single exchange allocation and status.
class ExchangeCard extends StatelessWidget {
  const ExchangeCard({required this.data, this.onTap, super.key});

  final ExchangeCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final effectivePctColor = data.percent >= 0
        ? appColors?.bullish ?? Colors.green
        : appColors?.bearish ?? Colors.red;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: data.tint,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                data.initial,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: data.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        data.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 7),
                      if (data.isLive)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: effectivePctColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: effectivePctColor.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.kinds,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.05 * 9,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist Mono',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.percent >= 0 ? '+' : ''}${data.percent.toStringAsFixed(2)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist Mono',
                    color: effectivePctColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
