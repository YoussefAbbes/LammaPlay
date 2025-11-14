import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/models/question.dart';
import 'package:lamaplay/models/answer.dart';
import 'package:lamaplay/repositories/quiz_repository.dart';
import 'package:lamaplay/services/scoring_utils.dart';

/// Unique Answer Mode: Players only score points if their answer is unique (not chosen by others)
class UniqueAnswerScoringService {
  final _db = FirebaseFirestore.instance;
  final _quizRepo = QuizRepository();

  Future<void> scoreQuestion({
    required String sessionId,
    required int qIndex,
  }) async {
    try {
      final sessionSnap = await _db.collection('sessions').doc(sessionId).get();
      if (!sessionSnap.exists) return;
      final sessionData = sessionSnap.data()!;
      final quizId = sessionData['quizId'] as String;

      final questions = await _quizRepo.getQuestions(quizId);
      if (qIndex < 0 || qIndex >= questions.length) return;
      final question = questions[qIndex];

      // Fetch all answers
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

      // Count how many times each answer was selected
      final Map<String, int> answerCounts = {};
      final Map<String, List<String>> answerToPlayers = {};

      for (final entry in answers.entries) {
        final answerKey = entry.value.value.toString();
        answerCounts[answerKey] = (answerCounts[answerKey] ?? 0) + 1;
        answerToPlayers[answerKey] = [
          ...(answerToPlayers[answerKey] ?? []),
          entry.key,
        ];
      }

      // Get player scores
      final playersSnap = await _db
          .collection('sessions')
          .doc(sessionId)
          .collection('players')
          .get();

      final Map<String, int> preScores = {};
      for (final doc in playersSnap.docs) {
        preScores[doc.id] = (doc.data()['score'] as num?)?.toInt() ?? 0;
      }

      // Score each player
      final Map<String, Map<String, dynamic>> perPlayer = {};
      final Map<String, int> deltas = {};

      for (final entry in answers.entries) {
        final playerId = entry.key;
        final answer = entry.value;
        final answerKey = answer.value.toString();
        final timesSelected = answerCounts[answerKey] ?? 0;

        // Check if answer is correct
        bool correct = false;
        switch (question.type) {
          case QuestionType.mcq:
          case QuestionType.tf:
          case QuestionType.image:
            if (question.correctIndex != null && answer.value is int) {
              correct = answer.value == question.correctIndex;
            }
            break;
          case QuestionType.numeric:
            if (question.numericAnswer != null) {
              final guess = answer.value is num
                  ? answer.value as num
                  : num.tryParse(answer.value.toString());
              final score = ScoringUtils.numericScore(
                guess,
                question.numericAnswer,
              );
              correct = score >= 700;
            }
            break;
          default:
            correct = false;
        }

        // UNIQUE ANSWER LOGIC: Only award points if answer is unique AND correct
        int points = 0;
        bool isUnique = timesSelected == 1;

        if (correct && isUnique) {
          // Award bonus points for being unique!
          final speedMult = ScoringUtils.speedMultiplier(
            answer.timeMsFromStart,
            question.timeLimitSeconds * 1000,
          );
          points = ScoringUtils.mcqBase(true, speedMult);
          points = (points * 1.5).round(); // 50% bonus for uniqueness!
        }

        deltas[playerId] = points;
        perPlayer[playerId] = {
          'correct': correct,
          'isUnique': isUnique,
          'timesSelected': timesSelected,
          'basePoints': points,
          'delta': points,
          'total': (preScores[playerId] ?? 0) + points,
          'timeMs': answer.timeMsFromStart,
        };
      }

      // Calculate option counts
      final optionCounts = <String, int>{};
      for (final answer in answers.values) {
        final key = answer.value.toString();
        optionCounts[key] = (optionCounts[key] ?? 0) + 1;
      }

      // Write results
      await _db
          .collection('sessions')
          .doc(sessionId)
          .collection('results')
          .doc('q_$qIndex')
          .set({
            'perPlayer': perPlayer,
            'optionCounts': optionCounts,
            'answerCounts': answerCounts,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Update player scores
      final batch = _db.batch();
      deltas.forEach((playerId, delta) {
        final playerRef = _db
            .collection('sessions')
            .doc(sessionId)
            .collection('players')
            .doc(playerId);
        final isCorrect = perPlayer[playerId]!['correct'] as bool;
        final isUnique = perPlayer[playerId]!['isUnique'] as bool;
        batch.update(playerRef, {
          'score': FieldValue.increment(delta),
          'lastAnswerCorrect': isCorrect,
          'lastAnswerUnique': isUnique,
          'correctAnswers': FieldValue.increment(isCorrect ? 1 : 0),
          'totalAnswers': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      await batch.commit();
    } catch (e) {
      print('Unique answer scoring error: $e');
      rethrow;
    }
  }
}
