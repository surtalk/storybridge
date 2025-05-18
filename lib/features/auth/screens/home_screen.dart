import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:storybridge_app/features/stories/screens/new_story_screen.dart';
import '../controller/auth_service.dart';
import '../controller/login_page.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('StoryBridge'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.photoURL != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user!.photoURL!),
              ),
            SizedBox(height: 16),
            Text(
              'Welcome, ${user?.displayName ?? "User"}!',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 16),
            Text('Email: ${user?.email ?? ""}'),
            SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(Icons.create),
              label: Text("Create New Story"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NewStoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
