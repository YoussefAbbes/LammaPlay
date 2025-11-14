import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class HrissaCardsSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a unique 6-digit PIN for joining
  String generatePin() {
    final random = Random();
    final pin = (random.nextInt(900000) + 100000).toString();
    return pin;
  }

  /// Create a new Hrissa Cards multiplayer session
  Future<Map<String, String>> createSession({
    required String hostId,
    required String hostNickname,
  }) async {
    final pin = generatePin();
    final sessionId = _firestore.collection('sessions').doc().id;

    // Create session document
    await _firestore.collection('sessions').doc(sessionId).set({
      'pin': pin,
      'hostId': hostId,
      'gameMode': 'hrissaCardsMultiplayer',
      'status': 'waiting', // waiting, in_progress, finished
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'hrissaCard': null, // Will be populated when game starts
    });

    // Add host as first player
    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('players')
        .doc(hostId)
        .set({
          'nickname': hostNickname,
          'isHost': true,
          'score': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        });

    return {'sessionId': sessionId, 'pin': pin};
  }

  /// Find and join a session by PIN
  Future<String?> joinSessionByPin({
    required String pin,
    required String playerId,
    required String nickname,
  }) async {
    try {
      // Find session by PIN
      final querySnap = await _firestore
          .collection('sessions')
          .where('pin', isEqualTo: pin)
          .where('status', isEqualTo: 'waiting')
          .where('gameMode', isEqualTo: 'hrissaCardsMultiplayer')
          .limit(1)
          .get();

      if (querySnap.docs.isEmpty) {
        return null; // Session not found
      }

      final sessionId = querySnap.docs.first.id;

      // Add player to session
      await _firestore
          .collection('sessions')
          .doc(sessionId)
          .collection('players')
          .doc(playerId)
          .set({
            'nickname': nickname,
            'isHost': false,
            'score': 0,
            'joinedAt': FieldValue.serverTimestamp(),
          });

      return sessionId;
    } catch (e) {
      print('Error joining session: $e');
      return null;
    }
  }

  /// Check if a session exists and is joinable
  Future<bool> isSessionJoinable(String pin) async {
    try {
      final querySnap = await _firestore
          .collection('sessions')
          .where('pin', isEqualTo: pin)
          .where('status', isEqualTo: 'waiting')
          .where('gameMode', isEqualTo: 'hrissaCardsMultiplayer')
          .limit(1)
          .get();

      return querySnap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get session details
  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('sessions').doc(sessionId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// End the session
  Future<void> endSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'finished',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Leave session (for players)
  Future<void> leaveSession(String sessionId, String playerId) async {
    await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('players')
        .doc(playerId)
        .delete();
  }

  /// Get final scores/leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard(String sessionId) async {
    final querySnap = await _firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('players')
        .orderBy('score', descending: true)
        .get();

    return querySnap.docs.map((doc) {
      final data = doc.data();
      return {
        'playerId': doc.id,
        'nickname': data['nickname'] as String? ?? 'Player',
        'score': data['score'] as int? ?? 0,
        'isHost': data['isHost'] as bool? ?? false,
      };
    }).toList();
  }
}
