import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class UserService {
  UserService._();
  static final UserService _instance = UserService._();
  factory UserService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // Use email as the document ID, as requested.
  String _docIdFor(fb_auth.User user) {
    return user.email!.toLowerCase();
  }

  Future<void> upsertUserProfile(fb_auth.User user) async {
    final String email = user.email ?? '';
    if (email.isEmpty) return; // Only proceed when email exists

    final String? displayName = user.displayName;
    final now = FieldValue.serverTimestamp();

    final docRef = _users.doc(_docIdFor(user));
    final snap = await docRef.get();

    if (snap.exists) {
      await docRef.update({
        'displayName': displayName,
        'lastLogin': now,
      });
    } else {
      await docRef.set({
        'email': email,
        'displayName': displayName,
        'createdAt': now,
        'lastLogin': now,
      });
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String email) async {
    final doc = await _users.doc(email.toLowerCase()).get();
    return doc.data();
  }

  // Google sign-in helper (optional)
  Future<fb_auth.User?> signInWithGoogle() async {
    final fb_auth.FirebaseAuth auth = fb_auth.FirebaseAuth.instance;

    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // User canceled

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = fb_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the User
    final userCred = await auth.signInWithCredential(credential);
    return userCred.user;
  }
}
