import 'package:flutter/material.dart';

import '../../../domain/entities/venue.dart';
import '../../../presentation/theme/theme_extensions.dart';
import 'venue_style.dart';

class VenueHeader extends StatelessWidget {
  const VenueHeader({
    required this.venue,
    required this.kinds,
    required this.accent,
    super.key,
  });

  final Venue venue;
  final String kinds;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final fg = theme.colorScheme.onSurface;
    final fg3 = appColors?.tertiaryText ?? theme.colorScheme.onSurfaceVariant;
    final upColor = appColors?.bullish ?? Colors.green;
    final color = venueColor(venue, accent: accent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              venue.displayName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w600,
                letterSpacing: -0.02 * 20,
                fontSize: 20,
                color: fg,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: upColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: upColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'API LIVE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: upColor,
                    letterSpacing: 0.06 * 9,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          kinds,
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: 'JetBrains Mono',
            color: fg3,
            letterSpacing: 0.06 * 9,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
