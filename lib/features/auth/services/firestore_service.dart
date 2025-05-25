import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> saveStory(String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final storyRef = await _db
        .collection('users')
        .doc(user.uid)
        .collection('stories')
        .add({
          'title': title,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

    return storyRef.id;
  }

  Future<void> saveStoryPage({
    required String storyId,
    required String text,
    required List<String> imageUrls,
    required int pageNumber,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('stories')
        .doc(storyId)
        .collection('pages')
        .add({
          'text': text,
          'imageUrls': imageUrls,
          'pageNumber': pageNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
  }

  Future<List<Map<String, dynamic>>> fetchUserStories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot =
        await _db
            .collection('users')
            .doc(user.uid)
            .collection('stories')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> fetchStoryPages(String storyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot =
        await _db
            .collection('users')
            .doc(user.uid)
            .collection('stories')
            .doc(storyId)
            .collection('pages')
            .where('isActive', isEqualTo: true)
            .orderBy('pageNumber')
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
