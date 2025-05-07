import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIImageService {
  static Future<String?> generateImage(String prompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('Missing OpenAI API key');
      return null;
    }

    final url = Uri.parse('https://api.openai.com/v1/images/generations');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({'prompt': prompt, 'n': 1, 'size': '512x512'}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final imageUrl = data['data'][0]['url'];
      return imageUrl;
    } else {
      print('OpenAI image error: ${response.body}');
      return null;
    }
  }
}
