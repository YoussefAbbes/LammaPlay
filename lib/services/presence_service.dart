import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Presence service using Realtime Database.
/// Tracks online status and lastSeen per room/player.
class PresenceService {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  // RTDB structure:
  // /presence/rooms/{roomId}/players/{playerId} => { online: bool, lastSeen: ts }
  DatabaseReference _playerPresenceRef(String roomId, String uid) => _rtdb
      .ref('presence')
      .child('rooms')
      .child(roomId)
      .child('players')
      .child(uid);

  Future<void> goOnline(String roomId, String uid) async {
    final ref = _playerPresenceRef(roomId, uid);
    await ref.set({'online': true, 'lastSeen': ServerValue.timestamp});
    await ref.onDisconnect().update({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  Future<void> goOffline(String roomId, String uid) async {
    final ref = _playerPresenceRef(roomId, uid);
    await ref.update({'online': false, 'lastSeen': ServerValue.timestamp});
  }

  /// Convenient method using current user.
  Future<void> updateForCurrentUser(
    String roomId, {
    required bool online,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (online) {
      await goOnline(roomId, uid);
    } else {
      await goOffline(roomId, uid);
    }
  }

  /// Helper to join presence for current user (alias of updateForCurrentUser).
  Future<void> joinRoom(String roomId) =>
      updateForCurrentUser(roomId, online: true);

  /// Helper to leave presence for current user.
  Future<void> leaveRoom(String roomId) =>
      updateForCurrentUser(roomId, online: false);
}
