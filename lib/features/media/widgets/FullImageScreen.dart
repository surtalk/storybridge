import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FullImageScreen extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  const FullImageScreen({Key? key, this.imageUrl, this.imageBytes})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (imageBytes != null) {
      image = Image.memory(imageBytes!);
    } else if (kIsWeb || (imageUrl != null && imageUrl!.startsWith('http'))) {
      image = Image.network(imageUrl!);
    } else {
      image = Image.file(File(imageUrl!));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: InteractiveViewer(
        child: SingleChildScrollView(
          scrollDirection:
              Axis.vertical, // You can add horizontal scroll too if needed
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Center(child: image),
          ),
        ),
      ),
    );
  }
}
