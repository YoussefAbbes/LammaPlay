import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing global leaderboard across all quiz sessions
class GlobalLeaderboardService {
  final _db = FirebaseFirestore.instance;

  /// Update global stats for a player after a quiz session
  Future<void> updateGlobalStats({
    required String playerId,
    required String nickname,
    required int sessionScore,
    required int correctAnswers,
    required int totalAnswers,
  }) async {
    final globalRef = _db.collection('globalLeaderboard').doc(playerId);

    final doc = await globalRef.get();
    if (doc.exists) {
      // Update existing record
      await globalRef.update({
        'nickname': nickname, // Update in case it changed
        'totalScore': FieldValue.increment(sessionScore),
        'totalCorrectAnswers': FieldValue.increment(correctAnswers),
        'totalQuestions': FieldValue.increment(totalAnswers),
        'quizzesPlayed': FieldValue.increment(1),
        'lastPlayed': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new record
      await globalRef.set({
        'playerId': playerId,
        'nickname': nickname,
        'totalScore': sessionScore,
        'totalCorrectAnswers': correctAnswers,
        'totalQuestions': totalAnswers,
        'quizzesPlayed': 1,
        'firstPlayed': FieldValue.serverTimestamp(),
        'lastPlayed': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get top players globally
  Stream<QuerySnapshot<Map<String, dynamic>>> getTopPlayers({int limit = 100}) {
    return _db
        .collection('globalLeaderboard')
        .orderBy('totalScore', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Get player's global rank
  Future<int?> getPlayerRank(String playerId) async {
    final playerDoc = await _db
        .collection('globalLeaderboard')
        .doc(playerId)
        .get();
    if (!playerDoc.exists) return null;

    final playerScore = (playerDoc.data()?['totalScore'] as num?)?.toInt() ?? 0;

    final higherScorePlayers = await _db
        .collection('globalLeaderboard')
        .where('totalScore', isGreaterThan: playerScore)
        .get();

    return higherScorePlayers.docs.length + 1;
  }

  /// Get player's global stats
  Future<Map<String, dynamic>?> getPlayerStats(String playerId) async {
    final doc = await _db.collection('globalLeaderboard').doc(playerId).get();
    return doc.exists ? doc.data() : null;
  }
}
