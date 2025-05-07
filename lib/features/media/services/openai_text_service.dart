import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAITextService {
  static Future<String?> generateNextLine(String prompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('Missing OpenAI API key');
      return null;
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a children\'s story writer. Write the next line of the story.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 50,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data['choices'][0]['message']['content'];
      return content?.trim();
    } else {
      print('OpenAI text error: ${response.body}');
      return null;
    }
  }
}
