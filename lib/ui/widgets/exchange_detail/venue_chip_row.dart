import 'package:flutter/material.dart';

import '../../../domain/entities/venue.dart';
import '../../../presentation/theme/theme_extensions.dart';

class VenueChipRow extends StatelessWidget {
  const VenueChipRow({
    required this.selectedVenue,
    required this.onVenueSelected,
    super.key,
  });

  final Venue selectedVenue;
  final ValueChanged<Venue> onVenueSelected;

  static const _venues = [
    Venue.binance,
    Venue.bybit,
    Venue.okx,
    Venue.coinbase,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final fg = theme.colorScheme.onSurface;
    final fg2 = appColors?.subtleText ?? theme.colorScheme.onSurfaceVariant;
    final bg = theme.colorScheme.surface;
    final line = appColors?.borderSubtle ?? theme.dividerColor;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _venues.map((venue) {
          final isSelected = venue == selectedVenue;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _VenueChip(
              label: venue.displayName,
              isSelected: isSelected,
              onTap: () => onVenueSelected(venue),
              fg: fg,
              fg2: fg2,
              bg: bg,
              line: line,
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
    required this.onTap,
    required this.fg,
    required this.fg2,
    required this.bg,
    required this.line,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color fg;
  final Color fg2;
  final Color bg;
  final Color line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? fg : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: isSelected ? fg : line),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontFamily: 'Space Grotesk',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? bg : fg2,
          ),
        ),
      ),
    );
  }
}
