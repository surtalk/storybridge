import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import '../screens/home_screen.dart';
import '../screens/waiting_approval_screen.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: Text("Sign in with Google"),
          onPressed: () async {
            UserCredential? user = await _authService.signInWithGoogle();
            if (user != null) {
              final doc =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.user!.uid)
                      .get();
              bool isApproved = doc['isApproved'] ?? false;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          isApproved ? HomeScreen() : WaitingApprovalScreen(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
