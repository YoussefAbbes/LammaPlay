import 'package:firebase_auth/firebase_auth.dart';

/// Handles authentication; ensures an anonymous user exists.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> ensureSignedInAnonymously() async {
    final current = _auth.currentUser;
    if (current != null) return current;
    final cred = await _auth.signInAnonymously();
    return cred.user;
  }

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  Stream<User?> get userChanges => _auth.userChanges();
}
