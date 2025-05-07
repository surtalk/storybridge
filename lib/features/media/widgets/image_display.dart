import 'dart:io';
import 'package:flutter/material.dart';

class ImageDisplay extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;

  const ImageDisplay({super.key, this.imageUrl, this.imageFile});

  @override
  Widget build(BuildContext context) {
    if (imageFile != null) {
      return Image.file(imageFile!, height: 200);
    } else if (imageUrl != null) {
      return Image.network(imageUrl!, height: 200);
    } else {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No image")),
      );
    }
  }
}
