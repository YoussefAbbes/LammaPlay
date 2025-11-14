import 'package:cloud_firestore/cloud_firestore.dart';

/// Scoring service for "Majority Rules" (الأغلبية) game mode
/// Players get points for choosing the MOST popular answer
/// Opposite of UniqueAnswer - conformity wins!
class MajorityRulesScoringService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Score a question in Majority Rules mode
  /// Returns map of playerId -> points earned
  Future<Map<String, int>> scoreQuestion({
    required String sessionId,
    required int questionIndex,
    required int correctIndex,
  }) async {
    final scores = <String, int>{};

    // Get all answers for this question
    final answersSnap = await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('answers')
        .where('questionIndex', isEqualTo: questionIndex)
        .get();

    if (answersSnap.docs.isEmpty) {
      return scores; // No answers submitted
    }

    // Count frequency of each answer (only for correct answers)
    final answerFrequency = <int, int>{};
    final playerAnswers = <String, int>{}; // playerId -> answerIndex

    for (final doc in answersSnap.docs) {
      final data = doc.data();
      final playerId = data['playerId'] as String;
      final answerIndex = data['answerIndex'] as int?;

      if (answerIndex == null) continue;

      playerAnswers[playerId] = answerIndex;

      // Only count correct answers for majority
      if (answerIndex == correctIndex) {
        answerFrequency[answerIndex] = (answerFrequency[answerIndex] ?? 0) + 1;
      }
    }

    // If nobody got it right, everyone gets 0
    if (answerFrequency.isEmpty) {
      for (final playerId in playerAnswers.keys) {
        scores[playerId] = 0;
      }
      return scores;
    }

    // Find the most popular correct answer (should only be one - the correct one)
    final totalCorrectAnswers = answerFrequency[correctIndex] ?? 0;

    // Base points calculation
    const basePoints = 100;

    // Score each player
    for (final entry in playerAnswers.entries) {
      final playerId = entry.key;
      final answerIndex = entry.value;

      if (answerIndex != correctIndex) {
        // Wrong answer = 0 points
        scores[playerId] = 0;
      } else {
        // Correct answer - points based on how many others also got it right
        // More people = more points (majority wins!)
        // Scale: 1 person = 100pts, 2+ people = bonus scaling
        int points = basePoints;

        if (totalCorrectAnswers >= 5) {
          points = basePoints + 100; // Large majority: +100%
        } else if (totalCorrectAnswers >= 3) {
          points = basePoints + 50; // Good majority: +50%
        } else if (totalCorrectAnswers >= 2) {
          points = basePoints + 25; // Small majority: +25%
        }
        // Solo correct answer = just base points (no bonus)

        scores[playerId] = points;
      }
    }

    return scores;
  }

  /// Get statistics for the question (for display)
  Future<Map<String, dynamic>> getQuestionStats({
    required String sessionId,
    required int questionIndex,
    required int correctIndex,
  }) async {
    final answersSnap = await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('answers')
        .where('questionIndex', isEqualTo: questionIndex)
        .get();

    final answerCounts = <int, int>{};
    int totalAnswers = 0;
    int correctAnswers = 0;

    for (final doc in answersSnap.docs) {
      final answerIndex = doc.data()['answerIndex'] as int?;
      if (answerIndex == null) continue;

      totalAnswers++;
      answerCounts[answerIndex] = (answerCounts[answerIndex] ?? 0) + 1;

      if (answerIndex == correctIndex) {
        correctAnswers++;
      }
    }

    return {
      'totalAnswers': totalAnswers,
      'correctAnswers': correctAnswers,
      'answerDistribution': answerCounts,
      'majoritySize': correctAnswers,
      'majorityPercentage': totalAnswers > 0
          ? (correctAnswers / totalAnswers * 100).round()
          : 0,
    };
  }
}
