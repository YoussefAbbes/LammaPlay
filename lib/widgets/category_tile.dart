import 'package:flutter/material.dart';
import 'package:lamaplay/core/theme/gradients.dart';
import 'package:lamaplay/core/theme/shadows.dart';

class CategoryTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? emoji;
  final bool selected;
  final VoidCallback? onTap;
  final bool cool;
  const CategoryTile({
    super.key,
    required this.title,
    this.subtitle,
    this.emoji,
    this.selected = false,
    this.onTap,
    this.cool = false,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: cool ? LmGradients.tileCool : LmGradients.tileWarm,
          borderRadius: BorderRadius.circular(16),
          boxShadow: LmShadows.card,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 28)),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: selected ? 1 : 0.0,
                child: const Icon(Icons.check_circle, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
