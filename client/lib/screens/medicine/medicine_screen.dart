import 'package:flutter/material.dart';

import '../../providers/medicine_provider.dart';
import '../../services/camera_service.dart';
import '../../widgets/medicine/camera_viewfinder.dart';

/// Main screen for selecting and previewing a medicine package image.
///
/// The caller owns [provider] and may inject a [cameraService] for platform
/// selection behavior. This screen does not identify or upload the image.
class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key, required this.provider, this.cameraService});

  final MedicineProvider provider;
  final CameraService? cameraService;

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  late final CameraService _cameraService;
  String? _selectionError;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _cameraService = widget.cameraService ?? CameraService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Vision AI')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListenableBuilder(
                listenable: widget.provider,
                builder: (context, _) => SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 480 ? 16 : 28,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Identify a medicine',
                        style: TextStyle(
                          color: Color(0xFF102A43),
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Take a photo or choose a photo of the medicine package '
                        'to get started.',
                        style: TextStyle(
                          color: Color(0xFF263238),
                          fontSize: 19,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSelectionButtons(),
                      if (widget.provider.selectedImage != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const ValueKey('clear-medicine-image'),
                          onPressed: _isSelecting
                              ? null
                              : widget.provider.reset,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Clear selected image'),
                          style: _buttonStyle(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      CameraViewfinder(image: widget.provider.selectedImage),
                      if (_isSelecting) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Opening image source',
                          ),
                        ),
                      ],
                      if (widget.provider.isLoading) ...[
                        const SizedBox(height: 20),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                        const Text(
                          'Working on your request…',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF102A43),
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (widget.provider.errorMessage case final message?)
                        _buildError(
                          message,
                          onDismiss: widget.provider.clearError,
                        ),
                      if (_selectionError case final message?)
                        _buildError(message, onDismiss: _clearSelectionError),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttons = [
          ElevatedButton.icon(
            key: const ValueKey('open-camera'),
            onPressed: _isSelecting
                ? null
                : () => _selectImage(fromCamera: true),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Take a photo'),
            style: _buttonStyle(),
          ),
          OutlinedButton.icon(
            key: const ValueKey('open-gallery'),
            onPressed: _isSelecting
                ? null
                : () => _selectImage(fromCamera: false),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from gallery'),
            style: _buttonStyle(),
          ),
        ];

        if (constraints.maxWidth >= 560) {
          return Row(
            children: [
              Expanded(child: buttons[0]),
              const SizedBox(width: 16),
              Expanded(child: buttons[1]),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [buttons[0], const SizedBox(height: 12), buttons[1]],
        );
      },
    );
  }

  ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
    minimumSize: const Size(0, 60),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _buildError(String message, {required VoidCallback onDismiss}) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F0),
            border: Border.all(color: const Color(0xFF8B1E12), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF68180F),
                  fontSize: 18,
                  height: 1.4,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectImage({required bool fromCamera}) async {
    setState(() {
      _isSelecting = true;
      _selectionError = null;
    });

    try {
      final result = fromCamera
          ? await _cameraService.captureMedicinePackage()
          : await _cameraService.selectFromGallery();
      if (!mounted) return;

      if (result.status == CameraServiceStatus.selected &&
          result.image != null) {
        widget.provider.selectImage(result.image);
      } else if (result.status != CameraServiceStatus.cancelled) {
        setState(() {
          _selectionError = result.message ?? 'Could not select this image.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectionError =
              'Could not open the image source. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSelecting = false);
    }
  }

  void _clearSelectionError() {
    setState(() => _selectionError = null);
  }
}
