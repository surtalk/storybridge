import 'dart:typed_data';

class StoryPage {
  String text;
  String? aiSuggestion;
  String? imageUrl;
  Uint8List? webImageBytes;

  bool isLoading;
  StoryPage({
    required this.text,
    this.aiSuggestion,
    this.imageUrl,
    this.webImageBytes,
    this.isLoading = false,
  });
}
