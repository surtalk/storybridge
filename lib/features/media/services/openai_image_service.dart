// lib/services/openai_image_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIImageService {
  final String firebaseFunctionUrl =
      'https://us-central1-storybridgeapp-4993a.cloudfunctions.net/proxyDalleImage';

  Future<String?> generateImage(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(firebaseFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['imageUrl'];
        print('Generated image URL: $imageUrl');

        if (imageUrl != null && imageUrl.startsWith('http')) {
          return imageUrl;
        } else {
          print('Image URL invalid or missing.');
          return null;
        }
      } else {
        print('Error from Firebase Function: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Image generation error: $e');
      return null;
    }
  }
}
