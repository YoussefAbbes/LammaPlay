import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shows animated feedback for correct/wrong answers
class AnswerFeedback extends StatelessWidget {
  final bool isCorrect;
  final int pointsEarned;
  final VoidCallback? onComplete;

  const AnswerFeedback({
    super.key,
    required this.isCorrect,
    this.pointsEarned = 0,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Correct/Wrong Icon
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCorrect
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                ),
                child: Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  size: 80,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              )
              .animate(onComplete: (_) => onComplete?.call())
              .scale(duration: 300.ms, curve: Curves.elasticOut)
              .then()
              .shake(hz: isCorrect ? 0 : 4, duration: 400.ms),

          const SizedBox(height: 24),

          // Text feedback
          Text(
            isCorrect ? 'Correct!' : 'Wrong!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0),

          if (isCorrect && pointsEarned > 0) ...[
            const SizedBox(height: 12),
            Text(
                  '+$pointsEarned points',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms)
                .scale(delay: 200.ms, duration: 300.ms),
          ],
        ],
      ),
    );
  }
}

/// Overlay that shows confetti animation
class ConfettiOverlay extends StatelessWidget {
  const ConfettiOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: List.generate(30, (index) {
          final random = index * 17; // pseudo-random
          return Positioned(
            left: (random % 100) * (MediaQuery.of(context).size.width / 100),
            top: -20,
            child:
                Icon(
                      Icons.star,
                      color: [
                        Colors.yellow,
                        Colors.orange,
                        Colors.pink,
                        Colors.purple,
                        Colors.blue,
                      ][random % 5],
                      size: 20 + (random % 20).toDouble(),
                    )
                    .animate(onComplete: (controller) => controller.repeat())
                    .moveY(
                      begin: 0,
                      end: MediaQuery.of(context).size.height + 50,
                      duration: (2000 + (random % 1000)).ms,
                      delay: (random % 500).ms,
                      curve: Curves.easeIn,
                    )
                    .fadeOut(begin: 0.8),
          );
        }),
      ),
    );
  }
}

/// Show streak achievement notification
class StreakNotification extends StatelessWidget {
  final int streakCount;

  const StreakNotification({super.key, required this.streakCount});

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.pink.shade400],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$streakCount Question Streak!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'You\'re on fire! 🔥',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .slideY(begin: -1, duration: 400.ms, curve: Curves.elasticOut)
        .fadeIn();
  }
}
