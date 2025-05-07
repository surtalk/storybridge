class StoryPage {
  String text;
  String? aiSuggestion;
  String? imageUrl; // Can be either uploaded or AI generated

  StoryPage({required this.text, this.aiSuggestion, this.imageUrl});
}
