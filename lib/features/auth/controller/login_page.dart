import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: Text('Sign in with Google'),
          onPressed: () async {
            await AuthService().signInWithGoogle();
            // 🔁 Browser will redirect; no navigation needed
          },
        ),
      ),
    );
  }
}
