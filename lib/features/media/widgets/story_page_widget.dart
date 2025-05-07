import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StoryPageWidget extends StatelessWidget {
  final String text;
  final String? imageUrl;
  final VoidCallback onTTS;
  final VoidCallback onImageTap;

  const StoryPageWidget({
    super.key,
    required this.text,
    this.imageUrl,
    required this.onTTS,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            GestureDetector(
              onTap: onImageTap,
              child: Image.network(imageUrl!, height: 150, fit: BoxFit.cover),
            ),
          Padding(padding: const EdgeInsets.all(8.0), child: Text(text)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.volume_up), onPressed: onTTS),
            ],
          ),
        ],
      ),
    );
  }
}
