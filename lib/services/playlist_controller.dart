import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/services/firestore_refs.dart';
import 'package:lamaplay/services/auth_service.dart';

/// Host-controlled playlist updates broadcast via Firestore.
class PlaylistController {
  final _auth = AuthService();

  Future<void> updatePlaylist(String roomId, List<String> playlist) async {
    final roomRef = FirestoreRefs.roomDoc(roomId);
    final roomSnap = await roomRef.get();
    if (roomSnap.data()?['hostId'] != _auth.uid) {
      throw StateError('Only host can update playlist');
    }
    await roomRef.update({
      'playlist': playlist,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
