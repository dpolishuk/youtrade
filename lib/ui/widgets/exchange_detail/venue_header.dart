import 'package:flutter/material.dart';

import '../../../domain/entities/venue.dart';
import 'venue_style.dart';

class VenueHeader extends StatelessWidget {
  const VenueHeader({
    required this.venue,
    required this.allocationPercent,
    required this.kinds,
    super.key,
  });

  final Venue venue;
  final double allocationPercent;
  final String kinds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = venueColor(venue);

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
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${allocationPercent.toStringAsFixed(1)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'Geist Mono',
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          kinds,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.06 * 9,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
