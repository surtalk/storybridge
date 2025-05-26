import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:storybridge_app/features/media/services/image_picker_service.dart';
import 'package:storybridge_app/features/media/services/openai_image_service.dart';
import 'package:storybridge_app/features/media/services/openai_text_service.dart';
import 'package:storybridge_app/features/stories/models/story.dart';
import 'package:storybridge_app/features/stories/models/story_page.dart';

class StoryEditorScreen extends StatefulWidget {
  final String storyTitle;

  const StoryEditorScreen({super.key, required this.storyTitle});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final _textService = OpenAiTextService();
  final _imageService = OpenAIImageService();
  final picker = ImagePickerService();

  final List<StoryPage> _storyPages = [];
  final List<TextEditingController> _controllers = [];
  final List<String?> _aiSuggestions = [];

  static const int maxImagesPerPage = 3;

  @override
  void initState() {
    super.initState();
    _addNewPage();
  }

  void _addNewPage() {
    setState(() {
      _storyPages.add(
        StoryPage(
          text: '',
          imageUrls: [],
          pageNumber: _storyPages.length + 1,
          createdAt: DateTime.now(),
          isActive: true,
        ),
      );
      _controllers.add(TextEditingController());
      _aiSuggestions.add(null);
    });
  }

  Future<void> _generateAISuggestion(int index) async {
    final prompt = _controllers[index].text;
    if (prompt.isEmpty) return;

    setState(() => _storyPages[index].isLoading = true);
    final suggestion = await _textService.fetchAISuggestion(prompt);

    setState(() {
      _aiSuggestions[index] = suggestion;
      _storyPages[index].isLoading = false;
    });
  }

  Future<void> _generateAIImage(int index) async {
    final prompt = _controllers[index].text;
    if (prompt.isEmpty ||
        _storyPages[index].imageUrls.length >= maxImagesPerPage)
      return;

    setState(() => _storyPages[index].isLoading = true);

    final imageUrl = await _imageService.generateImage(prompt);
    if (imageUrl != null) {
      setState(() {
        _storyPages[index].imageUrls.add(imageUrl);
        _storyPages[index].isLoading = false;
      });
    }
  }

  Future<void> _uploadImage(int index) async {
    if (_storyPages[index].imageUrls.length >= maxImagesPerPage) return;

    final (path, bytes) = await picker.pickImageFromGallery();

    setState(() {
      if (kIsWeb && bytes != null) {
        _storyPages[index].webImageBytes.add(bytes);
      } else if (path != null) {
        _storyPages[index].imageUrls.add(path);
      }
    });
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _saveStoryToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storyRef =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('stories')
            .doc();

    final storyId = storyRef.id;

    final story = Story(
      id: storyId,
      title: widget.storyTitle,
      createdAt: DateTime.now(),
      isActive: true,
    );

    await storyRef.set(story.toMap());

    for (int i = 0; i < _storyPages.length; i++) {
      final page = _storyPages[i];
      page.text = _controllers[i].text;
      page.pageNumber = i + 1;
      await storyRef.collection('pages').add(page.toMap());
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildImagePreviews(StoryPage page) {
    final images = page.imageUrls;

    return Column(
      children:
          images.asMap().entries.map((entry) {
            final index = entry.key;
            final imagePath = entry.value;

            Widget imageWidget;

            if (kIsWeb && !imagePath.startsWith('http')) {
              final bytes = page.getWebImageAt(index);
              imageWidget =
                  bytes != null
                      ? Image.memory(
                        bytes,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Text('Failed to load image'),
                      )
                      : const Text('Image not available');
            } else if (imagePath.startsWith('http')) {
              // Use proxy for DALL·E and other network images
              final proxyUrl =
                  'https://us-central1-storybridgeapp-4993a.cloudfunctions.net/proxyDalleImageGet?url=${Uri.encodeComponent(imagePath)}';

              imageWidget = Image.network(
                proxyUrl,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Text('Failed to load image'),
              );
            } else {
              // Local file image
              imageWidget = Image.file(
                File(imagePath),
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Text('Failed to load image'),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: imageWidget,
            );
          }).toList(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.storyTitle)),
      body: ListView.builder(
        itemCount: _storyPages.length,
        itemBuilder: (context, index) {
          final page = _storyPages[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _controllers[index],
                    maxLines: null,
                    decoration: InputDecoration(
                      labelText: 'Page ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (text) => page.text = text,
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
                  if (_aiSuggestions[index] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Suggestion: ${_aiSuggestions[index]!}'),
                          TextButton(
                            onPressed: () {
                              final suggestion = _aiSuggestions[index]!;
                              _controllers[index].text += ' $suggestion';
                              page.text = _controllers[index].text;
                              setState(() => _aiSuggestions[index] = null);
                            },
                            child: const Text('Accept Suggestion'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _generateAIImage(index),
                        icon: const Icon(Icons.image),
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
                  if (page.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  _buildImagePreviews(page),
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
            label: const Text('Add Page'),
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
