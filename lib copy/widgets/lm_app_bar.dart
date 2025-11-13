import 'package:flutter/material.dart';
import 'package:lamaplay/core/theme/gradients.dart';
import 'package:lamaplay/core/theme/spacing.dart';

/// LmAppBar: Minimal app bar with gradient background and large title.
class LmAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  const LmAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(gradient: LmGradients.banner),
      padding: const EdgeInsets.symmetric(horizontal: LmSpace.md),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}
