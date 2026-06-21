import 'package:flutter/material.dart';

/// A segment of an exchange allocation bar.
@immutable
class AllocationSegment {
  const AllocationSegment({
    required this.label,
    required this.color,
    required this.share,
  });

  final String label;
  final Color color;
  final double share;
}

/// Horizontal segmented bar showing allocation by venue.
class AllocationBar extends StatelessWidget {
  const AllocationBar({required this.segments, super.key});

  final List<AllocationSegment> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold(0.0, (sum, s) => sum + s.share);
    final effectiveTotal = total <= 0 ? 1.0 : total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Row(
            children: [
              for (final segment in segments)
                Expanded(
                  flex: (segment.share / effectiveTotal * 1000).round(),
                  child: Container(height: 9, color: segment.color),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
