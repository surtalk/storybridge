import 'package:flutter/material.dart';
import 'story_editor_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewStoryScreen extends StatefulWidget {
  const NewStoryScreen({super.key});

  @override
  State<NewStoryScreen> createState() => _NewStoryScreenState();
}

class _NewStoryScreenState extends State<NewStoryScreen> {
  final TextEditingController _titleController = TextEditingController();
  String? selectedTopic;

  final List<String> topics = [
    'Going to the park',
    'My feelings',
    'A trip to the zoo',
    'First day at school',
    'Playing with friends',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('New Story')),
        body: Center(child: Text('You must be logged in to create a story.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Story')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Story Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Choose a Topic',
                border: OutlineInputBorder(),
              ),
              value: selectedTopic,
              items:
                  topics.map((topic) {
                    return DropdownMenuItem(value: topic, child: Text(topic));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTopic = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty && selectedTopic != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => StoryEditorScreen(
                            storyTitle: _titleController.text, // ✅ correct name
                          ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a title and select a topic.'),
                    ),
                  );
                }
              },
              child: const Text('Start Story'),
            ),
          ],
        ),
      ),
    );
  }
}
