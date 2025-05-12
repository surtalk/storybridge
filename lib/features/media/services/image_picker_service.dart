import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<(String? path, Uint8List? bytes)> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return (null, null);

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      return (null, bytes); // No File path on web
    } else {
      return (image.path, null); // No bytes needed on mobile
    }
  }
}
