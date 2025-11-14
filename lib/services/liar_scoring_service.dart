import 'package:cloud_firestore/cloud_firestore.dart';

/// Scoring service for "The Liar" (الكذاب) game mode - Two Truths and One Lie
///
/// Flow:
/// 1. Each player submits 3 statements (stored in their answer doc)
/// 2. Other players vote on which statement is the lie (1, 2, or 3)
/// 3. Points awarded for:
///    - Fooling others (your lie wasn't detected)
///    - Correctly guessing others' lies
class LiarScoringService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Score results for The Liar game mode
  ///
  /// Expected answer structure:
  /// {
  ///   'playerId': 'player1',
  ///   'statements': ['statement1', 'statement2', 'statement3'],
  ///   'lieIndex': 0, // Which one is the lie (0, 1, or 2)
  ///   'questionIndex': 0
  /// }
  ///
  /// Expected votes structure (separate collection):
  /// sessions/{sessionId}/liarVotes/{voteId}
  /// {
  ///   'voterId': 'player2',
  ///   'targetPlayerId': 'player1',
  ///   'votedLieIndex': 1, // Which statement they think is the lie
  ///   'questionIndex': 0
  /// }
  Future<Map<String, int>> scoreRound({
    required String sessionId,
    required int questionIndex,
  }) async {
    final scores = <String, int>{};

    // Get all player statements for this round
    final answersSnap = await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('answers')
        .where('questionIndex', isEqualTo: questionIndex)
        .get();

    if (answersSnap.docs.isEmpty) {
      return scores; // No submissions
    }

    // Build map of player -> their lie index
    final playerLies = <String, int>{};
    final allPlayers = <String>{};

    for (final doc in answersSnap.docs) {
      final data = doc.data();
      final playerId = data['playerId'] as String;
      final lieIndex = data['lieIndex'] as int?;

      if (lieIndex != null) {
        playerLies[playerId] = lieIndex;
        allPlayers.add(playerId);
      }
    }

    // Get all votes for this round
    final votesSnap = await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('liarVotes')
        .where('questionIndex', isEqualTo: questionIndex)
        .get();

    // Track votes for each player
    final votesAgainst = <String, List<Map<String, dynamic>>>{};

    for (final doc in votesSnap.docs) {
      final data = doc.data();
      final targetPlayerId = data['targetPlayerId'] as String;
      final voterId = data['voterId'] as String;
      final votedLieIndex = data['votedLieIndex'] as int;

      if (!votesAgainst.containsKey(targetPlayerId)) {
        votesAgainst[targetPlayerId] = [];
      }

      votesAgainst[targetPlayerId]!.add({
        'voterId': voterId,
        'votedIndex': votedLieIndex,
      });
    }

    // Initialize scores
    for (final playerId in allPlayers) {
      scores[playerId] = 0;
    }

    // Score calculation
    const pointsForFooling = 50; // Points per person you fooled
    const pointsForGuessing =
        100; // Points for correctly guessing someone's lie

    // Calculate points for each player
    for (final playerId in allPlayers) {
      final actualLieIndex = playerLies[playerId];
      if (actualLieIndex == null) continue;

      final votes = votesAgainst[playerId] ?? [];

      // Count how many people were fooled (voted wrong)
      int peopleFooled = 0;
      for (final vote in votes) {
        if (vote['votedIndex'] != actualLieIndex) {
          peopleFooled++;
        }
      }

      // Award points for fooling others
      scores[playerId] = scores[playerId]! + (peopleFooled * pointsForFooling);
    }

    // Award points for correct guesses
    for (final voteDoc in votesSnap.docs) {
      final data = voteDoc.data();
      final voterId = data['voterId'] as String;
      final targetPlayerId = data['targetPlayerId'] as String;
      final votedLieIndex = data['votedLieIndex'] as int;

      final actualLieIndex = playerLies[targetPlayerId];
      if (actualLieIndex != null && votedLieIndex == actualLieIndex) {
        // Correct guess!
        scores[voterId] = (scores[voterId] ?? 0) + pointsForGuessing;
      }
    }

    return scores;
  }

  /// Get detailed statistics for the round
  Future<Map<String, dynamic>> getRoundStats({
    required String sessionId,
    required int questionIndex,
  }) async {
    final answersSnap = await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('answers')
        .where('questionIndex', isEqualTo: questionIndex)
        .get();

    final votesSnap = await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('liarVotes')
        .where('questionIndex', isEqualTo: questionIndex)
        .get();

    final playerStats = <String, Map<String, dynamic>>{};

    // Build player stats
    for (final doc in answersSnap.docs) {
      final data = doc.data();
      final playerId = data['playerId'] as String;
      final lieIndex = data['lieIndex'] as int?;

      playerStats[playerId] = {
        'lieIndex': lieIndex,
        'votesReceived': 0,
        'correctGuesses': 0,
        'fooledCount': 0,
      };
    }

    // Count votes
    for (final doc in votesSnap.docs) {
      final data = doc.data();
      final targetPlayerId = data['targetPlayerId'] as String;
      final voterId = data['voterId'] as String;
      final votedLieIndex = data['votedLieIndex'] as int;

      if (playerStats.containsKey(targetPlayerId)) {
        playerStats[targetPlayerId]!['votesReceived'] =
            (playerStats[targetPlayerId]!['votesReceived'] as int) + 1;

        // Check if correct
        final actualLieIndex = playerStats[targetPlayerId]!['lieIndex'] as int?;
        if (actualLieIndex != null && votedLieIndex == actualLieIndex) {
          // Voter guessed correctly
          if (playerStats.containsKey(voterId)) {
            playerStats[voterId]!['correctGuesses'] =
                (playerStats[voterId]!['correctGuesses'] as int) + 1;
          }
        } else {
          // Player fooled the voter
          playerStats[targetPlayerId]!['fooledCount'] =
              (playerStats[targetPlayerId]!['fooledCount'] as int) + 1;
        }
      }
    }

    return {
      'totalPlayers': playerStats.length,
      'totalVotes': votesSnap.docs.length,
      'playerStats': playerStats,
    };
  }

  /// Submit a player's statements and lie
  Future<void> submitStatements({
    required String sessionId,
    required String playerId,
    required int questionIndex,
    required List<String> statements,
    required int lieIndex,
  }) async {
    if (statements.length != 3) {
      throw Exception('Must provide exactly 3 statements');
    }
    if (lieIndex < 0 || lieIndex > 2) {
      throw Exception('Lie index must be 0, 1, or 2');
    }

    await _db.collection('sessions').doc(sessionId).collection('answers').add({
      'playerId': playerId,
      'questionIndex': questionIndex,
      'statements': statements,
      'lieIndex': lieIndex,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Submit a vote for someone's lie
  Future<void> submitVote({
    required String sessionId,
    required String voterId,
    required String targetPlayerId,
    required int questionIndex,
    required int votedLieIndex,
  }) async {
    if (voterId == targetPlayerId) {
      throw Exception('Cannot vote on your own statements');
    }
    if (votedLieIndex < 0 || votedLieIndex > 2) {
      throw Exception('Voted lie index must be 0, 1, or 2');
    }

    await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('liarVotes')
        .add({
          'voterId': voterId,
          'targetPlayerId': targetPlayerId,
          'questionIndex': questionIndex,
          'votedLieIndex': votedLieIndex,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
