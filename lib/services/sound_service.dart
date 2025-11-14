import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Service for managing sound effects throughout the app
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;

  /// Toggle sound on/off
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  /// Enable/disable sound
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Play a sound effect
  Future<void> play(SoundEffect effect) async {
    if (!_soundEnabled) return;

    try {
      // Using system sounds for now (can be replaced with custom audio files later)
      switch (effect) {
        case SoundEffect.buttonTap:
          HapticFeedback.lightImpact();
          break;
        case SoundEffect.success:
          HapticFeedback.mediumImpact();
          break;
        case SoundEffect.error:
          HapticFeedback.heavyImpact();
          break;
        case SoundEffect.celebration:
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          HapticFeedback.heavyImpact();
          break;
        case SoundEffect.whoosh:
          HapticFeedback.lightImpact();
          break;
        case SoundEffect.pop:
          HapticFeedback.selectionClick();
          break;
        case SoundEffect.tick:
          HapticFeedback.selectionClick();
          break;
        case SoundEffect.correctAnswer:
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 50));
          HapticFeedback.lightImpact();
          break;
        case SoundEffect.wrongAnswer:
          HapticFeedback.heavyImpact();
          break;
        case SoundEffect.countdown:
          HapticFeedback.selectionClick();
          break;
        case SoundEffect.uniqueAnswer:
          // Special effect for unique answer
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          HapticFeedback.lightImpact();
          break;
        case SoundEffect.spicyQuestion:
          // Hot/spicy effect for hrissa mode
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 80));
          HapticFeedback.mediumImpact();
          break;
        case SoundEffect.truthOrDare:
          // Dramatic effect for truth or dare
          HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 50));
          HapticFeedback.mediumImpact();
          break;
      }
    } catch (e) {
      // Silently fail if haptic feedback is not available
    }
  }

  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}

/// Available sound effects
enum SoundEffect {
  buttonTap,
  success,
  error,
  celebration,
  whoosh,
  pop,
  tick,
  correctAnswer,
  wrongAnswer,
  countdown,
  uniqueAnswer,
  spicyQuestion,
  truthOrDare,
}
