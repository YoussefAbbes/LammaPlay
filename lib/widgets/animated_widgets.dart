import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Enhanced animated button with ripple and bounce effects
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double elevation;
  final bool enablePulse;
  final bool enableBounce;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.elevation = 4,
    this.enablePulse = false,
    this.enableBounce = true,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: widget.backgroundColor ?? Theme.of(context).primaryColor,
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      elevation: _isPressed ? widget.elevation / 2 : widget.elevation,
      shadowColor: (widget.backgroundColor ?? Theme.of(context).primaryColor)
          .withOpacity(0.3),
      child: InkWell(
        onTap: widget.onPressed,
        onTapDown: widget.enableBounce
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.enableBounce
            ? (_) => setState(() => _isPressed = false)
            : null,
        onTapCancel: widget.enableBounce
            ? () => setState(() => _isPressed = false)
            : null,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding:
              widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: DefaultTextStyle(
            style: TextStyle(
              color: widget.foregroundColor ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    button = AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: button,
    );

    if (widget.enablePulse && widget.onPressed != null) {
      button = button
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            duration: 2000.ms,
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
          )
          .shimmer(
            delay: 500.ms,
            duration: 2000.ms,
            color: Colors.white.withOpacity(0.3),
          );
    }

    return button;
  }
}

/// Floating action button with ripple animation
class FloatingRippleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final String? tooltip;

  const FloatingRippleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 56,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple effect background
        Container(
              width: size * 1.5,
              height: size * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (backgroundColor ?? Theme.of(context).primaryColor)
                    .withOpacity(0.2),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.5, 1.5),
              duration: 2000.ms,
            )
            .fade(begin: 0.5, end: 0.0),

        // Main button
        Material(
              color: backgroundColor ?? Theme.of(context).primaryColor,
              shape: const CircleBorder(),
              elevation: 8,
              shadowColor: (backgroundColor ?? Theme.of(context).primaryColor)
                  .withOpacity(0.4),
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                splashColor: Colors.white.withOpacity(0.3),
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: iconColor ?? Colors.white,
                    size: size * 0.5,
                  ),
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              duration: 3000.ms,
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
            ),
      ],
    );
  }
}

/// Card with press animation
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        margin: widget.margin ?? const EdgeInsets.all(8),
        padding: widget.padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.color ?? Colors.white,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isPressed ? 0.05 : 0.1),
              blurRadius: _isPressed ? 8 : 16,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
        ),
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.98 : 1.0, _isPressed ? 0.98 : 1.0),
        child: widget.child,
      ),
    );
  }
}

/// Loading spinner with custom animation
class AnimatedLoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const AnimatedLoadingSpinner({super.key, this.size = 48, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: (color ?? Theme.of(context).primaryColor).withOpacity(
                  0.2,
                ),
                width: 3,
              ),
            ),
          ),
          // Spinning arc
          SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? Theme.of(context).primaryColor,
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1000.ms),
        ],
      ),
    );
  }
}

/// Success checkmark animation
class AnimatedCheckmark extends StatelessWidget {
  final double size;
  final Color? color;

  const AnimatedCheckmark({super.key, this.size = 64, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (color ?? Colors.green).withOpacity(0.1),
          ),
          child: Icon(
            Icons.check_circle,
            size: size * 0.8,
            color: color ?? Colors.green,
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.0, 0.0),
          duration: 400.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn();
  }
}

/// Error animation
class AnimatedErrorIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AnimatedErrorIcon({super.key, this.size = 64, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (color ?? Colors.red).withOpacity(0.1),
      ),
      child: Icon(Icons.error, size: size * 0.8, color: color ?? Colors.red),
    ).animate().shake(duration: 500.ms, hz: 5).fadeIn();
  }
}
