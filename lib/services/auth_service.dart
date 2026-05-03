import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'user_service.dart';

/// Google Sign-In + Firebase Auth operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();

  /// Currently logged in user - null if not logged in
  User? get currentUser => _auth.currentUser;

  /// Stream - login/logout state changes ට react කරන්න
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Google Sign-In flow - Google account picker open කරනවා
  Future<UserCredential?> signInWithGoogle() async {
    // Google account picker screen
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    // Google auth tokens get කරනවා
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Firebase credential හදනවා
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Firebase ට sign in කරනවා
    final userCredential = await _auth.signInWithCredential(credential);

    // First login නම් Firestore ේ user document create කරනවා
    if (userCredential.user != null) {
      await _userService.ensureUserDocument(userCredential.user!);
    }

    return userCredential;
  }

  /// Sign out - Firebase + Google දෙකෙන්ම
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Delete account - re-authenticate with Google then delete Firebase user
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Firebase requires recent auth before deleting — re-authenticate first
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await user.reauthenticateWithCredential(credential);
    await user.delete();
    await _googleSignIn.signOut();
  }
}
