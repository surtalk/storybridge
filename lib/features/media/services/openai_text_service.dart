import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAiTextService {
  static const String _cloudFunctionUrl =
      'https://us-central1-storybridgeapp-4993a.cloudfunctions.net/proxyOpenAiText'; // Replace with your actual URL

  Future<String?> fetchAISuggestion(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'];
      } else {
        print('Failed to get AI suggestion: ${response.body}');
      }
    } catch (e) {
      print('Error getting AI suggestion: $e');
    }
    return null;
  }
}
