import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static Future<String?> generateImage(String prompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    final url = Uri.parse("https://api.openai.com/v1/images/generations");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"prompt": prompt, "n": 1, "size": "512x512"}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'][0]['url'];
    } else {
      print("Image generation error: ${response.body}");
      return null;
    }
  }
}
