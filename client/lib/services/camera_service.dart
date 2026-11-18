import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

const int _maximumImageBytes = 5000000;

typedef ImageSelectionFunction = Future<XFile?> Function(ImageSource source);

enum CameraServiceStatus {
  selected,
  cancelled,
  permissionDenied,
  invalidImage,
  error,
}

/// The outcome of a camera or gallery selection.
class CameraServiceResult {
  const CameraServiceResult._({required this.status, this.image, this.message});

  const CameraServiceResult.selected(XFile image)
    : this._(status: CameraServiceStatus.selected, image: image);

  const CameraServiceResult.cancelled()
    : this._(
        status: CameraServiceStatus.cancelled,
        message: 'Image selection was cancelled.',
      );

  const CameraServiceResult.permissionDenied(String message)
    : this._(status: CameraServiceStatus.permissionDenied, message: message);

  const CameraServiceResult.invalidImage(String message)
    : this._(status: CameraServiceStatus.invalidImage, message: message);

  const CameraServiceResult.error(String message)
    : this._(status: CameraServiceStatus.error, message: message);

  final CameraServiceStatus status;
  final XFile? image;
  final String? message;

  bool get isSelected => status == CameraServiceStatus.selected;
  bool get isCancelled => status == CameraServiceStatus.cancelled;
}

/// Captures a medicine package image or selects one from the gallery.
///
/// Images are validated locally and are never uploaded by this service. An
/// [imageSelectionFunction] can be supplied to test callers without invoking
/// platform UI.
class CameraService {
  CameraService({ImageSelectionFunction? imageSelectionFunction})
    : _imageSelectionFunction =
          imageSelectionFunction ??
          ((source) => ImagePicker().pickImage(source: source));

  final ImageSelectionFunction _imageSelectionFunction;

  /// Opens the device camera to capture a medicine package photograph.
  Future<CameraServiceResult> captureMedicinePackage() =>
      _selectAndValidate(ImageSource.camera);

  /// Opens the device gallery to select an existing medicine package image.
  Future<CameraServiceResult> selectFromGallery() =>
      _selectAndValidate(ImageSource.gallery);

  Future<CameraServiceResult> _selectAndValidate(ImageSource source) async {
    try {
      final image = await _imageSelectionFunction(source);
      if (image == null) return const CameraServiceResult.cancelled();

      final size = await image.length();
      if (size > _maximumImageBytes) {
        return const CameraServiceResult.invalidImage(
          'Image must be 5 MB or smaller.',
        );
      }

      final bytes = await image.readAsBytes();
      if (bytes.length > _maximumImageBytes) {
        return const CameraServiceResult.invalidImage(
          'Image must be 5 MB or smaller.',
        );
      }
      if (!_isJpeg(bytes) && !_isPng(bytes)) {
        return const CameraServiceResult.invalidImage(
          'Choose a JPEG or PNG image.',
        );
      }

      return CameraServiceResult.selected(image);
    } on PlatformException catch (error) {
      if (_isPermissionDenial(error)) {
        final deviceFeature = source == ImageSource.camera
            ? 'camera'
            : 'photos';
        return CameraServiceResult.permissionDenied(
          'Permission to access $deviceFeature was denied. Enable access in '
          'device settings and try again.',
        );
      }
      return CameraServiceResult.error(
        'Could not open the image source. Please try again.',
      );
    } catch (_) {
      return const CameraServiceResult.error(
        'Could not read the image. Please try again.',
      );
    }
  }

  bool _isPermissionDenial(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    return code.contains('denied') ||
        code.contains('permission') ||
        message.contains('permission denied') ||
        message.contains('access denied');
  }

  bool _isJpeg(List<int> bytes) =>
      bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF;

  bool _isPng(List<int> bytes) =>
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;
}
