import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/models/question.dart';
import 'package:lamaplay/models/answer.dart';
import 'package:lamaplay/repositories/quiz_repository.dart';
import 'package:lamaplay/services/scoring_utils.dart';

/// Host-side scoring service: calculates and writes results after each question.
class HostScoringService {
  final _db = FirebaseFirestore.instance;
  final _quizRepo = QuizRepository();

  /// Score a question and update all player scores/streaks.
  Future<void> scoreQuestion({
    required String sessionId,
    required int qIndex,
  }) async {
    try {
      // 1. Get session and question data
      final sessionSnap = await _db.collection('sessions').doc(sessionId).get();
      if (!sessionSnap.exists) return;
      final sessionData = sessionSnap.data()!;
      final quizId = sessionData['quizId'] as String;

      final questions = await _quizRepo.getQuestions(quizId);
      if (qIndex < 0 || qIndex >= questions.length) return;
      final question = questions[qIndex];

      // 2. Fetch all answers for this question
      final answersSnap = await _db
          .collection('sessions')
          .doc(sessionId)
          .collection('answers')
          .where('qIndex', isEqualTo: qIndex)
          .get();

      final answers = <String, PlayerAnswer>{};
      for (final doc in answersSnap.docs) {
        final ans = PlayerAnswer.fromDoc(doc);
        answers[ans.playerId] = ans;
      }

      // 3. Get current player data (scores, streaks)
      final playersSnap = await _db
          .collection('sessions')
          .doc(sessionId)
          .collection('players')
          .get();

      final Map<String, int> preScores = {};
      final Map<String, int> streaks = {};
      for (final doc in playersSnap.docs) {
        preScores[doc.id] = (doc.data()['score'] as num?)?.toInt() ?? 0;
        streaks[doc.id] = (doc.data()['streak'] as num?)?.toInt() ?? 0;
      }

      // 4. Calculate median pre-score for catch-up bonus
      final sortedScores = preScores.values.toList()..sort();
      final medianPreScore = sortedScores.isEmpty
          ? 0
          : sortedScores.length % 2 == 0
          ? ((sortedScores[sortedScores.length ~/ 2 - 1] +
                    sortedScores[sortedScores.length ~/ 2]) ~/
                2)
          : sortedScores[sortedScores.length ~/ 2];

      // 5. Score each player
      final Map<String, Map<String, dynamic>> perPlayer = {};
      final Map<String, int> deltas = {};
      int fastestCorrectTime = 999999999;
      String? fastestCorrectPlayer;

      final timeLimitMs = question.timeLimitSeconds * 1000;

      for (final entry in answers.entries) {
        final playerId = entry.key;
        final answer = entry.value;

        // Determine correctness
        bool correct = false;
        int basePoints = 0;

        switch (question.type) {
          case QuestionType.mcq:
          case QuestionType.tf:
          case QuestionType.image:
            if (question.correctIndex != null && answer.value is int) {
              correct = answer.value == question.correctIndex;
            }
            if (correct) {
              final speedMult = ScoringUtils.speedMultiplier(
                answer.timeMsFromStart,
                timeLimitMs,
              );
              basePoints = ScoringUtils.mcqBase(true, speedMult);
            }
            break;

          case QuestionType.numeric:
            if (question.numericAnswer != null) {
              final guess = answer.value is num
                  ? answer.value as num
                  : num.tryParse(answer.value.toString());
              basePoints = ScoringUtils.numericScore(
                guess,
                question.numericAnswer,
              );
              correct = basePoints >= 700; // Consider 70%+ correct
            }
            break;

          case QuestionType.order:
            if (question.orderSolution != null) {
              // Handle both string format "0,2,1,3" and List format
              List<dynamic> playerOrder;
              if (answer.value is String) {
                // Parse string format to list of indices
                playerOrder = (answer.value as String)
                    .split(',')
                    .map((s) => int.tryParse(s.trim()) ?? 0)
                    .toList();
              } else if (answer.value is List) {
                playerOrder = answer.value as List;
              } else {
                playerOrder = [];
              }

              basePoints = ScoringUtils.orderBase(
                playerOrder,
                question.orderSolution,
              );
              correct = basePoints >= 700;
            }
            break;

          case QuestionType.poll:
            // Polls don't score
            correct = false;
            basePoints = 0;
            break;
        }

        // Track fastest correct
        if (correct && answer.timeMsFromStart < fastestCorrectTime) {
          fastestCorrectTime = answer.timeMsFromStart;
          fastestCorrectPlayer = playerId;
        }

        // Update streak
        if (correct) {
          streaks[playerId] = (streaks[playerId] ?? 0) + 1;
        } else {
          streaks[playerId] = 0;
        }

        perPlayer[playerId] = {
          'correct': correct,
          'basePoints': basePoints,
          'timeMs': answer.timeMsFromStart,
        };
      }

      // 6. Apply bonuses
      for (final playerId in perPlayer.keys) {
        final data = perPlayer[playerId]!;
        final correct = data['correct'] as bool;
        int basePoints = data['basePoints'] as int;

        if (!correct) {
          deltas[playerId] = 0;
          perPlayer[playerId] = {
            ...data,
            'delta': 0,
            'total': preScores[playerId] ?? 0,
            'bonuses': {},
          };
          continue;
        }

        final bonuses = <String, int>{};

        // Streak bonus
        final streakCount = streaks[playerId] ?? 0;
        final streakBonus = ScoringUtils.streakBonus(streakCount);
        if (streakBonus > 0) bonuses['streak'] = streakBonus;

        // Fastest correct bonus
        if (playerId == fastestCorrectPlayer) {
          bonuses['fastest'] = ScoringUtils.fastestBonus(true);
        }

        // Catch-up bonus
        final preScore = preScores[playerId] ?? 0;
        final catchUpBonus = ScoringUtils.catchUpBonus(
          preScore,
          medianPreScore,
        );
        if (catchUpBonus > 0) bonuses['catchup'] = catchUpBonus;

        // Calculate total
        final bonusSum = bonuses.values.fold<int>(0, (a, b) => a + b);
        final total = ScoringUtils.capTotal(basePoints + bonusSum);
        deltas[playerId] = total;

        perPlayer[playerId] = {
          ...data,
          'delta': total,
          'total': (preScores[playerId] ?? 0) + total,
          'bonuses': bonuses,
        };
      }

      // 7. Calculate option counts for display
      final optionCounts = <String, int>{};
      for (final answer in answers.values) {
        final key = answer.value.toString();
        optionCounts[key] = (optionCounts[key] ?? 0) + 1;
      }

      // 8. Write results doc
      await _db
          .collection('sessions')
          .doc(sessionId)
          .collection('results')
          .doc('q_$qIndex')
          .set({
            'perPlayer': perPlayer,
            'optionCounts': optionCounts,
            'medianPreScore': medianPreScore,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 9. Batch update player scores and streaks
      final batch = _db.batch();
      deltas.forEach((playerId, delta) {
        final playerRef = _db
            .collection('sessions')
            .doc(sessionId)
            .collection('players')
            .doc(playerId);
        batch.update(playerRef, {
          'score': FieldValue.increment(delta),
          'streak': streaks[playerId] ?? 0,
          'lastAnswerCorrect': perPlayer[playerId]!['correct'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      await batch.commit();
    } catch (e) {
      print('Scoring error: $e');
      rethrow;
    }
  }
}
