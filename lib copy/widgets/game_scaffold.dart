import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/core/theme/gradients.dart';
import 'package:lamaplay/core/theme/spacing.dart';

/// A unified visual wrapper for game screens: photo/gradient header + content card area.
class GameScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? heroImage; // asset path
  final Widget? timer;
  final Widget body;
  final Widget? bottomBar;
  final EdgeInsetsGeometry padding;
  final List<Widget>? actions;

  const GameScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.heroImage,
    this.timer,
    this.bottomBar,
    this.actions,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final headerHeight = isWide ? 220.0 : 180.0;
        return Stack(
          children: [
            // Background gradient "energy" layer
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: LmGradients.banner),
              ),
            ),
            // Scrollable content
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  expandedHeight: headerHeight,
                  pinned: true,
                  elevation: 0,
                  actions: actions,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _HeaderImage(heroImage: heroImage),
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: 16,
                      bottom: 12,
                    ),
                    title:
                        Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle!,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                              ],
                            )
                            .animate()
                            .fade(duration: 400.ms)
                            .moveY(begin: 12, end: 0, curve: Curves.easeOut),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: padding.horizontal > 0
                          ? (padding is EdgeInsets
                                ? (padding as EdgeInsets).left
                                : 16)
                          : 16,
                      right: padding.horizontal > 0
                          ? (padding is EdgeInsets
                                ? (padding as EdgeInsets).right
                                : 16)
                          : 16,
                      top: padding.vertical > 0
                          ? (padding is EdgeInsets
                                ? (padding as EdgeInsets).top
                                : 16)
                          : 16,
                      bottom: bottomBar == null ? 32 : 96,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (timer != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: LmSpace.sm),
                            child: timer!,
                          ),
                        body
                            .animate()
                            .fadeIn(duration: 250.ms)
                            .slideY(begin: .05, end: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (bottomBar != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(child: bottomBar!),
              ),
          ],
        );
      },
    );
  }
}

class _HeaderImage extends StatelessWidget {
  final String? heroImage;
  const _HeaderImage({this.heroImage});

  @override
  Widget build(BuildContext context) {
    final image = heroImage;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (image != null)
          Image.asset(
            image,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
        // Gradient overlay for readability
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.black.withOpacity(0.55),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
