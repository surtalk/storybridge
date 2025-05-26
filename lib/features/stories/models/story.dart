// story.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String title;
  final bool isActive;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.title,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'storyId': id,
    'title': title,
    'isActive': isActive,
    'createdAt': createdAt,
  };

  factory Story.fromMap(Map<String, dynamic> map, String id) {
    return Story(
      id: id,
      title: map['title'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
