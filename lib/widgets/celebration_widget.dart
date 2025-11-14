import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

/// Celebration widget with confetti effect for winners
class CelebrationWidget extends StatefulWidget {
  final Widget child;
  final bool autoPlay;
  final Duration duration;

  const CelebrationWidget({
    super.key,
    required this.child,
    this.autoPlay = true,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<CelebrationWidget> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: widget.duration);
    if (widget.autoPlay) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _confettiController.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        widget.child,

        // Left confetti
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 4, // 45 degrees to the right
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 30,
            minBlastForce: 15,
            gravity: 0.3,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),

        // Right confetti
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3 * pi / 4, // 135 degrees to the left
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 30,
            minBlastForce: 15,
            gravity: 0.3,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),

        // Center confetti (optional, for extra celebration)
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // Straight down
            emissionFrequency: 0.03,
            numberOfParticles: 15,
            maxBlastForce: 20,
            minBlastForce: 10,
            gravity: 0.2,
            colors: const [
              Colors.amber,
              Colors.deepOrange,
              Colors.red,
              Colors.teal,
            ],
          ),
        ),
      ],
    );
  }

  /// Manually trigger confetti
  void play() {
    _confettiController.play();
  }

  /// Stop confetti
  void stop() {
    _confettiController.stop();
  }
}

/// Simple confetti overlay that can be added to any widget
class ConfettiOverlay extends StatefulWidget {
  final Widget child;

  const ConfettiOverlay({super.key, required this.child});

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Trigger confetti burst
  void celebrate() {
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            maxBlastForce: 40,
            minBlastForce: 20,
            gravity: 0.3,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
              Colors.red,
              Colors.teal,
            ],
          ),
        ),
      ],
    );
  }
}

/// Usage examples:

// Example 1: Auto-play celebration
/*
CelebrationWidget(
  child: YourWidget(),
)
*/

// Example 2: Manual trigger
/*
final GlobalKey<ConfettiOverlayState> confettiKey = GlobalKey();

// In build:
ConfettiOverlay(
  key: confettiKey,
  child: YourWidget(),
)

// To trigger:
confettiKey.currentState?.celebrate();
*/

// Example 3: Podium screen integration
/*
class PodiumScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CelebrationWidget(
      child: Scaffold(
        body: // Your podium content
      ),
    );
  }
}
*/
