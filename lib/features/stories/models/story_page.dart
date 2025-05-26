import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryPage {
  String text;
  List<String> imageUrls;
  int pageNumber;
  bool isActive;
  DateTime createdAt;
  bool isLoading;
  List<Uint8List> webImageBytes; // Only used for web

  StoryPage({
    required this.text,
    this.imageUrls = const [],
    required this.pageNumber,
    required this.createdAt,
    this.isActive = true,
    this.isLoading = false,
    this.webImageBytes = const [],
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'imageUrls': imageUrls,
    'pageNumber': pageNumber,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory StoryPage.fromMap(Map<String, dynamic> map) {
    return StoryPage(
      text: map['text'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      pageNumber: map['pageNumber'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Uint8List? getWebImageAt(int index) =>
      index < webImageBytes.length ? webImageBytes[index] : null;
}
