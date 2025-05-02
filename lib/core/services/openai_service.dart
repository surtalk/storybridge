import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> getSuggestedText(String prompt) async {
    final url = Uri.parse("https://api.openai.com/v1/completions");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "text-davinci-003",
        "prompt": prompt,
        "max_tokens": 60,
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['text'].trim();
    } else {
      throw Exception('Failed to fetch AI suggestion');
    }
  }
}
