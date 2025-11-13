import 'package:flutter/material.dart';
import 'package:lamaplay/core/theme/colors.dart';

class StatBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatBadge.host({super.key})
    : label = 'HOST',
      color = LmColors.secondary;
  const StatBadge.offline({super.key})
    : label = 'OFFLINE',
      color = LmColors.warning;
  const StatBadge.winner({super.key})
    : label = 'WINNER',
      color = LmColors.accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
