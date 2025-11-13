import 'package:flutter/material.dart';
import 'package:lamaplay/core/theme/shadows.dart';

class LmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const LmCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: LmShadows.card,
      ),
      padding: padding,
      child: child,
    );
  }
}
