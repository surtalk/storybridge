import 'package:cloud_firestore/cloud_firestore.dart';

class StoryPage {
  final String text;
  final List<String> images;

  StoryPage({required this.text, required this.images});

  Map<String, dynamic> toMap() => {'text': text, 'images': images};

  factory StoryPage.fromMap(Map<String, dynamic> map) {
    return StoryPage(
      text: map['text'],
      images: List<String>.from(map['images']),
    );
  }
}

class Story {
  final String title;
  final DateTime createdAt;
  final List<StoryPage> pages;

  Story({required this.title, required this.createdAt, required this.pages});

  Map<String, dynamic> toMap() => {
    'title': title,
    'createdAt': createdAt,
    'pages': pages.map((p) => p.toMap()).toList(),
  };

  factory Story.fromMap(Map<String, dynamic> map) {
    return Story(
      title: map['title'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      pages: (map['pages'] as List).map((p) => StoryPage.fromMap(p)).toList(),
    );
  }
}
