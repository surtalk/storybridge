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
              final userId = user.user!.uid;

              try {
                final doc =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get();

                bool isApproved = false;

                if (doc.exists) {
                  final data = doc.data();
                  isApproved = data?['isApproved'] ?? false;
                  print("came here isApproved: $isApproved");
                }

                print("isApproved: $isApproved");

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => isApproved ? HomeScreen() : HomeScreen(),
                  ),
                );
              } catch (e) {
                print('Error checking approval status: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Login failed: Unable to verify approval.'),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
