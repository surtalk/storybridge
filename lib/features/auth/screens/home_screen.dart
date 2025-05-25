import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:storybridge_app/features/auth/controller/auth_service.dart';
import 'package:storybridge_app/features/auth/controller/login_page.dart';

import 'package:storybridge_app/features/stories/screens/new_story_screen.dart';

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
      body: Column(
        children: [
          const SizedBox(height: 16),
          if (user?.photoURL != null)
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(user!.photoURL!),
            ),
          const SizedBox(height: 12),
          Text(
            'Welcome, ${user?.displayName ?? "User"}!',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text('Email: ${user?.email ?? ""}'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.create),
            label: const Text("Create New Story"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NewStoryScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Your Stories", style: TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('stories')
                      .where('isActive', isEqualTo: true)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No stories found."));
                }

                final stories = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    final data = story.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(data['title'] ?? 'Untitled'),
                      subtitle: Text(
                        (data['createdAt'] as Timestamp)
                            .toDate()
                            .toLocal()
                            .toString(),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Open viewer/editor
                        // Navigator.push(context, MaterialPageRoute(
                        //   builder: (_) => ViewStoryScreen(storyId: story.id),
                        // ));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
