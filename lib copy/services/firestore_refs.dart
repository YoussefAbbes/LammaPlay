import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized Firestore collection/document references.
class FirestoreRefs {
  static final _db = FirebaseFirestore.instance;

  // Rooms
  static CollectionReference<Map<String, dynamic>> rooms() =>
      _db.collection('rooms');
  static DocumentReference<Map<String, dynamic>> roomDoc(String roomId) =>
      rooms().doc(roomId);

  // Players
  static CollectionReference<Map<String, dynamic>> players(String roomId) =>
      roomDoc(roomId).collection('players');
  static DocumentReference<Map<String, dynamic>> playerDoc(
    String roomId,
    String playerId,
  ) => players(roomId).doc(playerId);

  // Rounds
  static CollectionReference<Map<String, dynamic>> rounds(String roomId) =>
      roomDoc(roomId).collection('rounds');
  static DocumentReference<Map<String, dynamic>> roundDoc(
    String roomId,
    String roundId,
  ) => rounds(roomId).doc(roundId);

  // Subcollections under a round
  static CollectionReference<Map<String, dynamic>> submissions(
    String roomId,
    String roundId,
  ) => roundDoc(roomId, roundId).collection('submissions');
  static CollectionReference<Map<String, dynamic>> votes(
    String roomId,
    String roundId,
  ) => roundDoc(roomId, roundId).collection('votes');

  // Room secrets live in a top-level collection per requirements:
  // roomSecrets/{roomId}/rounds/{roundId}
  static CollectionReference<Map<String, dynamic>> roomSecretsRounds(
    String roomId,
  ) => _db.collection('roomSecrets').doc(roomId).collection('rounds');
  static DocumentReference<Map<String, dynamic>> roomSecretRoundDoc(
    String roomId,
    String roundId,
  ) => roomSecretsRounds(roomId).doc(roundId);
}
