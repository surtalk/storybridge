import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StoryEditorScreen extends StatefulWidget {
  final String storyTitle;

  const StoryEditorScreen({Key? key, required this.storyTitle})
    : super(key: key);

  @override
  _StoryEditorScreenState createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final List<TextEditingController> _controllers = [];
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  final List<String?> _aiSuggestions = [null];
  @override
  void initState() {
    super.initState();
    _addNewPage(); // Add the first page initially
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _addNewPage() {
    setState(() {
      _controllers.add(TextEditingController());
      _aiSuggestions.add(null);
    });

    // Auto-scroll to the new page after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _suggestNextLine(int index) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OpenAI API key not found')));
      return;
    }

    final prompt =
        _controllers[index].text.trim().isEmpty
            ? "Continue the story titled '${widget.storyTitle}':"
            : "Continue: ${_controllers[index].text}";

    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content":
                "You are helping children with autism continue a story using simple, encouraging language.",
          },
          {
            "role": "user",
            "content": "Continue this story: ${_controllers[index].text}",
          },
        ],
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      //final data = jsonDecode(response.body);
      //final suggestion = data['choices'][0]['text'];

      final data = json.decode(response.body);
      final suggestion = data['choices'][0]['message']['content'];

      setState(() {
        _aiSuggestions[index] = suggestion;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Error: ${response.statusCode}')),
      );
    }
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  void _acceptSuggestion(int index) {
    setState(() {
      _controllers[index].text += ' ' + (_aiSuggestions[index] ?? '');
      _aiSuggestions[index] = null;
    });
  }

  void _discardSuggestion(int index) {
    setState(() {
      _aiSuggestions[index] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.storyTitle)),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _controllers.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Page ${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controllers[index],
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Write story text...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _suggestNextLine(index),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("AI Suggest"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _speakText(_controllers[index].text),
                        icon: const Icon(Icons.volume_up),
                        label: const Text("Read Aloud"),
                      ),
                    ],
                  ),
                  if (_aiSuggestions.length > index &&
                      _aiSuggestions[index] != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      "AI Suggestion:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(_aiSuggestions[index]!),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _acceptSuggestion(index),
                          icon: Icon(Icons.check, color: Colors.green),
                          label: Text("Accept"),
                        ),
                        TextButton.icon(
                          onPressed: () => _discardSuggestion(index),
                          icon: Icon(Icons.clear, color: Colors.red),
                          label: Text("Discard"),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewPage,
        icon: const Icon(Icons.add),
        label: const Text("Add Page"),
      ),
    );
  }
}
