// Example usage of sound effects and animations throughout the app

import 'package:flutter/material.dart';
import 'package:lamaplay/services/sound_service.dart';
import 'package:lamaplay/utils/animated_effects.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Quick reference for implementing animations and sounds

// ============================================================================
// SOUND EFFECTS USAGE
// ============================================================================

class SoundEffectsExamples {
  // Button tap - Light feedback for any button press
  void onButtonTap() {
    SoundService().play(SoundEffect.buttonTap);
    // Your button logic here
  }

  // Success - Medium feedback for successful operations
  void onSuccess() {
    SoundService().play(SoundEffect.success);
    // Show success message
  }

  // Error - Heavy feedback for errors
  void onError() {
    SoundService().play(SoundEffect.error);
    // Show error message
  }

  // Celebration - Double heavy for major achievements
  void onQuizCompleted() {
    SoundService().play(SoundEffect.celebration);
    // Show celebration animation
  }

  // Whoosh - For transitions
  void onScreenTransition() {
    SoundService().play(SoundEffect.whoosh);
    // Navigate to new screen
  }

  // Correct answer - Two-stage feedback
  void onCorrectAnswer() {
    SoundService().play(SoundEffect.correctAnswer);
    // Show green checkmark
  }

  // Wrong answer - Heavy feedback
  void onWrongAnswer() {
    SoundService().play(SoundEffect.wrongAnswer);
    // Show red X
  }
}

// ============================================================================
// ANIMATION EXAMPLES
// ============================================================================

class AnimationExamples extends StatelessWidget {
  const AnimationExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Staggered list items
        ...List.generate(
          5,
          (index) => AnimatedEffects.staggeredListItem(
            index: index,
            child: ListTile(title: Text('Item $index')),
          ),
        ),

        // 2. Floating decorative element
        AnimatedEffects.floatingElement(
          duration: const Duration(seconds: 4),
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple,
            ),
          ),
        ),

        // 3. Success celebration
        AnimatedEffects.successCelebration(
          child: const Icon(Icons.check_circle, size: 80, color: Colors.green),
        ),

        // 4. Error shake
        AnimatedEffects.errorShake(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red,
            child: const Text('Error message'),
          ),
        ),

        // 5. Shimmer loading
        AnimatedEffects.shimmerLoading(
          baseColor: Colors.purple,
          child: Container(width: 200, height: 20, color: Colors.grey[300]),
        ),

        // 6. Scale bounce on appear
        AnimatedEffects.scaleBounce(
          child: ElevatedButton(onPressed: () {}, child: const Text('Button')),
        ),

        // 7. Slide in from bottom
        AnimatedEffects.slideIn(
          begin: const Offset(0, 1),
          child: const Card(child: Text('Slide from bottom')),
        ),

        // 8. Rotate in
        AnimatedEffects.rotateIn(
          turns: 0.25,
          child: const Icon(Icons.star, size: 50),
        ),
      ],
    );
  }
}

// ============================================================================
// FLUTTER_ANIMATE EXAMPLES
// ============================================================================

class FlutterAnimateExamples extends StatelessWidget {
  const FlutterAnimateExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple fade in
        Container(color: Colors.blue, height: 100).animate().fadeIn(),

        // Fade + slide combo
        Container(
          color: Colors.red,
          height: 100,
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0),

        // Scale with delay
        Container(
          color: Colors.green,
          height: 100,
        ).animate().scale(delay: 200.ms, duration: 400.ms),

        // Shimmer effect (repeating)
        Container(color: Colors.purple, height: 100)
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1500.ms),

        // Multiple animations in sequence
        Container(color: Colors.orange, height: 100)
            .animate()
            .fadeIn(duration: 300.ms)
            .then()
            .scale(duration: 200.ms)
            .then()
            .shimmer(duration: 1000.ms),

        // Custom curves
        Container(color: Colors.teal, height: 100).animate().slideX(
          begin: 1,
          end: 0,
          curve: Curves.elasticOut,
          duration: 600.ms,
        ),
      ],
    );
  }
}

// ============================================================================
// ANIMATED BACKGROUND
// ============================================================================

class AnimatedBackgroundExample extends StatelessWidget {
  const AnimatedBackgroundExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      color1: const Color(0xFF667eea),
      color2: const Color(0xFF764ba2),
      showFloatingElements: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: const Text(
            'Content with animated background',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// COMBINED EXAMPLE - Interactive Button
// ============================================================================

class AnimatedSoundButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const AnimatedSoundButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: () {
            // Play sound
            SoundService().play(SoundEffect.buttonTap);
            // Call callback
            onPressed();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(duration: 400.ms, curve: Curves.elasticOut);
  }
}

// ============================================================================
// FORM WITH ANIMATIONS
// ============================================================================

class AnimatedFormExample extends StatefulWidget {
  const AnimatedFormExample({super.key});

  @override
  State<AnimatedFormExample> createState() => _AnimatedFormExampleState();
}

class _AnimatedFormExampleState extends State<AnimatedFormExample> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated text field that shakes on error
        TextField(
          decoration: const InputDecoration(labelText: 'Username'),
        ).animate(target: _hasError ? 1 : 0).shake(duration: 500.ms),

        // Submit button with scale animation
        ElevatedButton(
          onPressed: () {
            setState(() => _hasError = true);
            SoundService().play(SoundEffect.error);
          },
          child: const Text('Submit'),
        ).animate().scale(
          delay: 100.ms,
          duration: 300.ms,
          curve: Curves.elasticOut,
        ),
      ],
    );
  }
}

// ============================================================================
// LIST WITH STAGGERED ANIMATION
// ============================================================================

class StaggeredListExample extends StatelessWidget {
  final List<String> items;

  const StaggeredListExample({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return AnimatedEffects.staggeredListItem(
          index: index,
          child: Card(
            child: ListTile(
              title: Text(items[index]),
              onTap: () {
                SoundService().play(SoundEffect.buttonTap);
                // Handle tap
              },
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// BEST PRACTICES
// ============================================================================

/*
1. SOUND EFFECTS:
   - Use buttonTap for any interactive element
   - Use success for positive outcomes
   - Use error for failures
   - Use celebration for major achievements
   - Keep sounds short and non-intrusive

2. ANIMATIONS:
   - Keep durations between 200-600ms for most animations
   - Use elastic curves for playful effects
   - Use ease curves for smooth transitions
   - Stagger list animations by 50-100ms per item
   - Don't overdo animations - less is more

3. PERFORMANCE:
   - Use const constructors where possible
   - Avoid rebuilding animated widgets unnecessarily
   - Use RepaintBoundary for complex animations
   - Test on actual devices, not just emulator

4. ACCESSIBILITY:
   - Provide visual feedback along with sounds
   - Keep haptic feedback subtle
   - Consider adding toggle for animations/sounds
   - Respect system reduced motion preferences (future)

5. CONSISTENCY:
   - Use the same animation duration for similar actions
   - Maintain consistent sound feedback across similar interactions
   - Follow the established color scheme
   - Keep the animation style unified
*/
