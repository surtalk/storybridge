import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // GoogleSignIn for Web (with clientId) and Mobile (without clientId)
  GoogleSignIn get _googleSignIn =>
      kIsWeb
          ? GoogleSignIn(
            clientId:
                '1056200996320-edlinogi803e33f3uk7l7jhblqp6sv4h.apps.googleusercontent.com',
          )
          : GoogleSignIn();

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        await _saveUser(userCredential);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final result = await _auth.signInWithCredential(credential);
        await _saveUser(result);
      }
    } catch (e) {
      print("🔴 Google sign-in error: $e");
    }
  }

  Future<void> handleRedirectLogin() async {
    try {
      final result = await _auth.getRedirectResult();
      if (result.user != null) {
        await _saveUser(result);
        print("✅ Redirect login complete");
      }
    } catch (e) {
      print("⚠️ Redirect login failed: $e");
    }
  }

  Future<void> _saveUser(UserCredential userCredential) async {
    final user = userCredential.user!;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'isApproved': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
