import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;
  const OptionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.disabled = false,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: disabled ? Colors.black12 : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: fg),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: fg.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: selected ? 1 : 0,
              child: Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
