import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/services/firestore_refs.dart';
import 'package:lamaplay/models/room.dart' as model;
import 'package:lamaplay/models/player.dart' as model;

/// Client-authoritative RoomController: create/join/leave, streams, host detection.
class RoomController {
  final _db = FirebaseFirestore.instance;
  final _auth = AuthService();
  final _uuid = const Uuid();

  Stream<model.Room?> roomStream(String roomId) => FirestoreRefs.roomDoc(roomId)
      .snapshots()
      .map((s) => s.exists ? model.Room.fromJson(s.id, s.data()!) : null);

  Stream<List<model.Player>> playersStream(String roomId) =>
      FirestoreRefs.players(roomId).snapshots().map(
        (snap) => snap.docs
            .map((d) => model.Player.fromJson(d.id, d.data()))
            .toList(),
      );

  Future<String> createRoom({required String nickname}) async {
    final uid = _auth.uid!;
    final roomId = _uuid.v4().substring(0, 8);
    final code = roomId.toUpperCase();

    final batch = _db.batch();
    final roomRef = FirestoreRefs.roomDoc(roomId);
    batch.set(roomRef, {
      'code': code,
      'hostId': uid,
      'status': 'lobby',
      'playlist': <String>[],
      'roundIndex': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final playerRef = FirestoreRefs.playerDoc(roomId, uid);
    batch.set(playerRef, {
      'nickname': nickname,
      'avatar': null,
      'score': 0,
      'connected': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return roomId;
  }

  Future<String?> joinRoom({
    required String code,
    required String nickname,
  }) async {
    // Lookup room by code
    final q = await FirestoreRefs.rooms()
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    final room = q.docs.first;
    final roomId = room.id;
    final uid = _auth.uid!;

    // Nickname uniqueness check
    final existing = await FirestoreRefs.players(
      roomId,
    ).where('nickname', isEqualTo: nickname).limit(1).get();
    if (existing.docs.isNotEmpty && existing.docs.first.id != uid) {
      throw StateError('Nickname already taken');
    }

    await FirestoreRefs.playerDoc(roomId, uid).set({
      'nickname': nickname,
      'avatar': null,
      'score': 0,
      'connected': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return roomId;
  }

  Future<void> leaveRoom(String roomId) async {
    final uid = _auth.uid!;
    await FirestoreRefs.playerDoc(roomId, uid).set({
      'connected': false,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> isHost(String roomId) async {
    final uid = _auth.uid!;
    final room = await FirestoreRefs.roomDoc(roomId).get();
    return room.data()?['hostId'] == uid;
  }
}
