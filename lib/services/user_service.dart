import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User document Firestore ේ manage කරනවා
/// Role check + user document create
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Login වෙනකොට user document නෑ නම් create කරනවා
  /// Already exist නම් touch නෑ - role preserve කරනවා
  Future<void> ensureUserDocument(User user) async {
    final doc = _users.doc(user.uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      // First login - user document create, default role: 'user'
      await doc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'role': 'user', // admin කරන්නේ manually Firebase Console ෙකන්
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Current user ගේ role get කරනවා - 'user' | 'admin'
  Stream<String> getUserRoleStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 'user';
      return doc.data()?['role'] as String? ?? 'user';
    });
  }
}
