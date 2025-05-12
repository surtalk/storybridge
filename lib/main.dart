import 'package:flutter/material.dart';
import 'features/stories/screens/new_story_screen.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NewStoryScreen(), // ← You’ll change this during development
    );
  }
}
