import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Collection of reusable animated widgets and effects
class AnimatedEffects {
  /// Animated button with scale and glow effect
  static Widget animatedButton({
    required Widget child,
    required VoidCallback onPressed,
    Color glowColor = Colors.purple,
    double scale = 1.05,
  }) {
    return child
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(
          delay: 2000.ms,
          duration: 1500.ms,
          color: glowColor.withOpacity(0.3),
        );
  }

  /// Staggered list animation
  static Widget staggeredListItem({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return child
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * delay.inMilliseconds).ms)
        .slideX(begin: 0.3, end: 0, duration: 400.ms);
  }

  /// Floating animation for decorative elements
  static Widget floatingElement({
    required Widget child,
    Duration duration = const Duration(seconds: 3),
  }) {
    return child
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(begin: 0, end: -20, duration: duration, curve: Curves.easeInOut);
  }

  /// Pulsing glow effect
  static Widget pulsingGlow({
    required Widget child,
    Color glowColor = Colors.purple,
    Duration duration = const Duration(seconds: 2),
  }) {
    return child
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .boxShadow(
          begin: BoxShadow(
            color: glowColor.withOpacity(0.0),
            blurRadius: 0,
            spreadRadius: 0,
          ),
          end: BoxShadow(
            color: glowColor.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          duration: duration,
        );
  }

  /// Scale bounce animation
  static Widget scaleBounce({
    required Widget child,
    double scale = 1.1,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return child.animate().scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1.0, 1.0),
      duration: duration,
      curve: Curves.elasticOut,
    );
  }

  /// Rotate and fade in
  static Widget rotateIn({required Widget child, double turns = 0.5}) {
    return child
        .animate()
        .fadeIn(duration: 400.ms)
        .rotate(begin: turns, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  /// Slide in from direction
  static Widget slideIn({
    required Widget child,
    Offset begin = const Offset(0, 1),
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return child
        .animate()
        .fadeIn(duration: duration * 0.7)
        .slide(begin: begin, duration: duration, curve: Curves.easeOutCubic);
  }

  /// Success celebration animation
  static Widget successCelebration({required Widget child}) {
    return child
        .animate()
        .scale(
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.2, 1.2),
          duration: 300.ms,
          curve: Curves.elasticOut,
        )
        .then()
        .scale(
          begin: const Offset(1.2, 1.2),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
        );
  }

  /// Error shake animation
  static Widget errorShake({required Widget child}) {
    return child.animate().shake(duration: 500.ms, hz: 4, rotation: 0.05);
  }

  /// Shimmer loading effect
  static Widget shimmerLoading({
    required Widget child,
    Color baseColor = Colors.purple,
  }) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms, color: baseColor.withOpacity(0.5));
  }

  /// Card flip animation
  static Widget cardFlip({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return child.animate().flipV(duration: duration, curve: Curves.easeInOut);
  }

  /// Expanding circle reveal
  static Widget circleReveal({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return child
        .animate()
        .scale(
          begin: const Offset(0.0, 0.0),
          duration: duration,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: duration * 0.8);
  }
}

/// Decorative animated background elements
class AnimatedBackground extends StatelessWidget {
  final Widget child;
  final Color color1;
  final Color color2;
  final bool showFloatingElements;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.color1 = const Color(0xFF667eea),
    this.color2 = const Color(0xFF764ba2),
    this.showFloatingElements = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color1, color2],
            ),
          ),
        ),

        // Floating decorative elements
        if (showFloatingElements) ...[
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedEffects.floatingElement(
              duration: const Duration(seconds: 4),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: AnimatedEffects.floatingElement(
              duration: const Duration(seconds: 5),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        // Content
        child,
      ],
    );
  }
}
