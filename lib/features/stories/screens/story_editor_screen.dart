import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:storybridge_app/features/stories/models/story_page.dart';
import 'package:storybridge_app/features/media/services/openai_text_service.dart';
import 'package:storybridge_app/features/media/services/openai_image_service.dart';
import 'package:storybridge_app/features/media/services/image_picker_service.dart';

class StoryEditorScreen extends StatefulWidget {
  final String storyTitle;

  const StoryEditorScreen({super.key, required this.storyTitle});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final List<StoryPage> _storyPages = [StoryPage(text: '')];
  final List<TextEditingController> _controllers = [TextEditingController()];
  final List<String?> _aiSuggestions = [];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    flutterTts.stop();
    super.dispose();
  }

  void _addNewPage() {
    setState(() {
      _storyPages.add(StoryPage(text: ''));
      _controllers.add(TextEditingController());
      _aiSuggestions.add(null);
    });
  }

  @override
  void initState() {
    super.initState();
    _aiSuggestions.add(null);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _generateAISuggestion(int index) async {
    final prompt = _controllers[index].text;
    final suggestion = await OpenAITextService.generateNextLine(prompt);
    if (suggestion != null) {
      setState(() {
        _aiSuggestions[index] = suggestion;
      });
    }
  }

  Future<void> _generateAIImage(int index) async {
    final prompt = _controllers[index].text;
    final imageUrl = await OpenAIImageService.generateImage(prompt);
    if (imageUrl != null) {
      setState(() {
        _storyPages[index].imageUrl = imageUrl;
      });
    }
  }

  Future<void> _uploadImage(int index) async {
    final imageFile = await ImagePickerService.pickImageFromGallery();
    if (imageFile != null) {
      setState(() {
        _storyPages[index].imageUrl = imageFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.storyTitle)),
      body: ListView.builder(
        itemCount: _storyPages.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    controller: _controllers[index],
                    maxLines: null,
                    decoration: InputDecoration(
                      labelText: 'Page ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _storyPages[index].text = value;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _generateAISuggestion(index),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('AI Suggest'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _speak(_controllers[index].text),
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Read Aloud'),
                      ),
                    ],
                  ),
                  if (_aiSuggestions.length > index &&
                      _aiSuggestions[index] != null)
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'AI Suggestion: ${_aiSuggestions[index]!}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        TextButton(
                          onPressed: () {
                            _controllers[index].text +=
                                ' ${_aiSuggestions[index]!}';
                            _storyPages[index].text = _controllers[index].text;
                            setState(() {
                              _aiSuggestions[index] = null;
                            });
                          },
                          child: const Text('Accept Suggestion'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _generateAIImage(index),
                        icon: const Icon(Icons.image_search),
                        label: const Text('AI Image'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _uploadImage(index),
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Image'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_storyPages[index].imageUrl != null)
                    _storyPages[index].imageUrl!.startsWith('http')
                        ? Image.network(
                          _storyPages[index].imageUrl!,
                          height: 200,
                        )
                        : Image.file(
                          File(_storyPages[index].imageUrl!),
                          height: 200,
                        ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewPage,
        icon: const Icon(Icons.add),
        label: const Text('Add New Page'),
      ),
    );
  }
}
