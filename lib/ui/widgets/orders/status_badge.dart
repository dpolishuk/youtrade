import 'package:flutter/material.dart';

/// A compact status badge used for order sides and position sides.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    super.key,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06 * 8,
          color: foregroundColor,
        ),
      ),
    );
  }
}
