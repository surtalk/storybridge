import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:storybridge_app/features/media/widgets/FullImageScreen.dart';
import 'package:storybridge_app/features/stories/models/story_page.dart';
import 'package:storybridge_app/features/media/services/openai_text_service.dart';
import 'package:storybridge_app/features/media/services/openai_image_service.dart';
import 'package:storybridge_app/features/media/services/image_picker_service.dart';

class StoryEditorScreen extends StatefulWidget {
  final String storyTitle;
  static const int maxImagesPerPage = 3;
  const StoryEditorScreen({super.key, required this.storyTitle});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final List<StoryPage> _storyPages = [StoryPage(text: '', imageUrl: null)];
  final List<TextEditingController> _controllers = [TextEditingController()];
  final List<String?> _aiSuggestions = [];
  final _imageService = OpenAIImageService();
  final _textService = OpenAiTextService();
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
      _storyPages.add(StoryPage(text: '', imageUrl: null));
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
    setState(() {
      _storyPages[index].isLoading = true;
    });
    final prompt = _controllers[index].text;
    final suggestion = await _textService.fetchAISuggestion(prompt);
    if (suggestion != null) {
      setState(() {
        _aiSuggestions[index] = suggestion;
        _storyPages[index].isLoading = false;
      });
    }
  }

  Future<void> _generateAIImage(int index) async {
    setState(() {
      _storyPages[index].isLoading = true;
    });
    if (index >= _controllers.length || index >= _storyPages.length) return;

    final prompt = _controllers[index].text;
    if (prompt.isEmpty) return;

    final imageUrl = await _imageService.generateImage(prompt);
    if (imageUrl != null && index < _storyPages.length) {
      setState(() {
        print("image url" + imageUrl);
        _storyPages[index].imageUrl = imageUrl;
        _storyPages[index].isLoading = false;
      });
    }
  }

  Future<void> _uploadImage(int index) async {
    final picker = ImagePickerService();
    final (path, bytes) = await picker.pickImageFromGallery();

    setState(() {
      if (kIsWeb) {
        _storyPages[index].webImageBytes = bytes;
        _storyPages[index].imageUrl = null;
      } else {
        _storyPages[index].imageUrl = path;
        _storyPages[index].webImageBytes = null;
      }
    });
  }

  Future<void> _saveStoryToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storyRef =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('stories')
            .doc(); // auto-id

    final storyId = storyRef.id;

    final storyData = {
      'title': widget.storyTitle,
      'createdAt': Timestamp.now(),
      'isActive': true,
      'storyId': storyId,
    };

    await storyRef.set(storyData);

    for (int i = 0; i < _storyPages.length; i++) {
      final page = _storyPages[i];

      final pageData = {
        'text': page.text,
        'imageUrl': page.imageUrl,
        'pageNumber': i + 1,
        'createdAt': Timestamp.now(),
        'isActive': true,
      };

      await storyRef.collection('pages').add(pageData);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Story saved successfully!')));

    Navigator.pop(context); // go back to Home screen
  }

  @override
  Widget build(BuildContext context) {
    // Defensive check to avoid index issues
    if (_controllers.length != _storyPages.length ||
        _aiSuggestions.length != _storyPages.length) {
      debugPrint('List lengths are inconsistent!');
      return const Center(child: CircularProgressIndicator());
    }
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
                  if (_storyPages[index].isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_storyPages[index].imageUrl != null ||
                      _storyPages[index].webImageBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => FullImageScreen(
                                    imageUrl:
                                        _storyPages[index].imageUrl!.startsWith(
                                              'http',
                                            )
                                            ? 'https://us-central1-storybridgeapp-4993a.cloudfunctions.net/proxyDalleImageGet?url=${Uri.encodeComponent(_storyPages[index].imageUrl!)}'
                                            : _storyPages[index].imageUrl,
                                    imageBytes:
                                        _storyPages[index].webImageBytes,
                                  ),
                            ),
                          );
                        },
                        child:
                            kIsWeb
                                ? _storyPages[index].imageUrl != null &&
                                        _storyPages[index].imageUrl!.startsWith(
                                          'http',
                                        )
                                    ? Image.network(
                                      'https://us-central1-storybridgeapp-4993a.cloudfunctions.net/proxyDalleImageGet?url=${Uri.encodeComponent(_storyPages[index].imageUrl!)}',
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Text(
                                                'Failed to load image.',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                    )
                                    : Image.memory(
                                      _storyPages[index].webImageBytes!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Text(
                                                'Failed to load image.',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                    )
                                : _storyPages[index].imageUrl != null &&
                                    _storyPages[index].imageUrl!.startsWith(
                                      'http',
                                    )
                                ? Image.network(
                                  'https://us-central1-storybridgeapp-4993a.cloudfunctions.net/proxyDalleImageGet?url=${Uri.encodeComponent(_storyPages[index].imageUrl!)}',
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Text(
                                            'Failed to load image.',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                )
                                : Image.file(
                                  File(_storyPages[index].imageUrl!),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Text(
                                            'Failed to load image.',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _addNewPage,
            icon: const Icon(Icons.add),
            label: const Text('Add New Page'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: _saveStoryToFirestore,
            icon: const Icon(Icons.save),
            label: const Text('Save Story'),
          ),
        ],
      ),
    );
  }
}
