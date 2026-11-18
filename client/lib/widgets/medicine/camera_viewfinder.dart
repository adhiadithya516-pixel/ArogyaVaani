import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shows the medicine package image selected by the camera service.
///
/// This widget only presents an image. Selecting, capturing, and uploading an
/// image are responsibilities of the caller and its services.
class CameraViewfinder extends StatefulWidget {
  const CameraViewfinder({super.key, this.image});

  final XFile? image;

  @override
  State<CameraViewfinder> createState() => _CameraViewfinderState();
}

class _CameraViewfinderState extends State<CameraViewfinder> {
  Future<Uint8List>? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CameraViewfinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _loadImage();
  }

  void _loadImage() {
    _imageBytes = widget.image?.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    return Semantics(
      container: true,
      label: image == null
          ? 'Medicine image preview. No image selected.'
          : 'Selected medicine image preview.',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7F9),
          border: Border.all(color: const Color(0xFF263238), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: image == null ? _buildPlaceholder() : _buildImage(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 56, color: Color(0xFF123B5D)),
            SizedBox(height: 12),
            Text(
              'No medicine image selected',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF102A43),
                fontSize: 21,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Choose or take a clear photo of the medicine package.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF263238),
                fontSize: 18,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return FutureBuilder<Uint8List>(
      future: _imageBytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildImageError();
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading selected medicine image',
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          key: const ValueKey('selected-medicine-image'),
          fit: BoxFit.contain,
          semanticLabel: 'Selected medicine package',
          errorBuilder: (context, error, stackTrace) => _buildImageError(),
        );
      },
    );
  }

  Widget _buildImageError() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'This image could not be displayed. Please choose another photo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF102A43), fontSize: 18, height: 1.4),
        ),
      ),
    );
  }
}
