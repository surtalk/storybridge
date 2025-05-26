import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:storybridge_app/features/stories/models/story.dart';
import 'package:storybridge_app/features/stories/models/story_page.dart';

class SlideshowScreen extends StatefulWidget {
  final String storyId;
  final String userId;

  const SlideshowScreen({
    super.key,
    required this.storyId,
    required this.userId,
  });

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  int _currentPageIndex = 0;
  final FlutterTts _tts = FlutterTts();
  Story? _story;
  List<StoryPage> _pages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStory();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _fetchStory() async {
    try {
      final storyDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('stories')
              .doc(widget.storyId)
              .get();

      if (!storyDoc.exists) {
        setState(() => _loading = false);
        return;
      }

      final story = Story.fromMap(storyDoc.data()!, storyDoc.id);

      final pagesSnapshot =
          await storyDoc.reference
              .collection('pages')
              .orderBy('pageNumber')
              .get();

      final pages =
          pagesSnapshot.docs.map((doc) {
            final page = StoryPage.fromMap(doc.data());
            return page;
          }).toList();

      setState(() {
        _story = story;
        _pages = pages;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _speakText(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  void _nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      setState(() => _currentPageIndex++);
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      setState(() => _currentPageIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_story == null || _pages.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Story not found or has no active pages.")),
      );
    }

    final StoryPage currentPage = _pages[_currentPageIndex];

    return Scaffold(
      appBar: AppBar(title: Text(_story!.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Page ${_currentPageIndex + 1} of ${_pages.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (currentPage.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        currentPage.text,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Column(
                    children:
                        currentPage.imageUrls.map((imageUrl) {
                          final proxyUrl =
                              'https://us-central1-storybridgeapp-4993a.cloudfunctions.net/proxyDalleImageGet?url=${Uri.encodeComponent(imageUrl)}';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                proxyUrl,
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Text("Image failed to load"),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _previousPage,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Previous"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _speakText(currentPage.text),
                  icon: const Icon(Icons.volume_up),
                  label: const Text("Read Aloud"),
                ),
                ElevatedButton.icon(
                  onPressed: _nextPage,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
