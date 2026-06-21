import 'package:flutter/material.dart';

import '../../../domain/entities/venue.dart';
import 'venue_style.dart';

class VenueChipRow extends StatelessWidget {
  const VenueChipRow({
    required this.selectedVenue,
    required this.onVenueSelected,
    super.key,
  });

  final Venue selectedVenue;
  final ValueChanged<Venue> onVenueSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: Venue.values.map((venue) {
          final isSelected = venue == selectedVenue;
          final color = venueColor(venue);

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _VenueChip(
              label: venue.displayName,
              isSelected: isSelected,
              color: isSelected ? theme.colorScheme.onSurface : color,
              backgroundColor: isSelected
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                  : theme.colorScheme.surfaceContainerHighest,
              borderColor: isSelected
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : theme.dividerColor,
              onTap: () => onVenueSelected(venue),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VenueChip extends StatelessWidget {
  const _VenueChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
