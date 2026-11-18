import 'package:arogyavani/services/camera_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  final jpeg = XFile.fromData(
    Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00]),
    name: 'medicine.jpg',
  );
  final png = XFile.fromData(
    Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
    name: 'medicine.png',
  );

  test('captures a JPEG photograph from the camera', () async {
    ImageSource? requestedSource;
    final service = CameraService(
      imageSelectionFunction: (source) async {
        requestedSource = source;
        return jpeg;
      },
    );

    final result = await service.captureMedicinePackage();

    expect(requestedSource, ImageSource.camera);
    expect(result.status, CameraServiceStatus.selected);
    expect(result.image, same(jpeg));
    expect(result.isSelected, isTrue);
  });

  test('selects a PNG from the gallery', () async {
    ImageSource? requestedSource;
    final service = CameraService(
      imageSelectionFunction: (source) async {
        requestedSource = source;
        return png;
      },
    );

    final result = await service.selectFromGallery();

    expect(requestedSource, ImageSource.gallery);
    expect(result.status, CameraServiceStatus.selected);
    expect(result.image, same(png));
  });

  test('treats cancellation as a normal result', () async {
    final service = CameraService(imageSelectionFunction: (_) async => null);

    final result = await service.captureMedicinePackage();

    expect(result.status, CameraServiceStatus.cancelled);
    expect(result.isCancelled, isTrue);
    expect(result.image, isNull);
    expect(result.message, isNotEmpty);
  });

  test('reports denied camera permission clearly', () async {
    final service = CameraService(
      imageSelectionFunction: (_) async =>
          throw PlatformException(code: 'camera_access_denied'),
    );

    final result = await service.captureMedicinePackage();

    expect(result.status, CameraServiceStatus.permissionDenied);
    expect(result.message, contains('camera'));
    expect(result.message, contains('device settings'));
  });

  test('accepts a valid JPEG of exactly 5,000,000 bytes', () async {
    final exactLimit = XFile.fromData(
      Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        ...List<int>.filled(5000000 - 3, 0),
      ]),
      name: 'exact-limit.jpg',
    );
    final service = CameraService(
      imageSelectionFunction: (_) async => exactLimit,
    );

    final result = await service.selectFromGallery();

    expect(await exactLimit.length(), 5000000);
    expect(result.status, CameraServiceStatus.selected);
    expect(result.image, same(exactLimit));
  });

  test('rejects images larger than 5,000,000 bytes', () async {
    final oversized = XFile.fromData(
      Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        ...List<int>.filled(5000001 - 3, 0),
      ]),
      name: 'large.jpg',
    );
    final service = CameraService(
      imageSelectionFunction: (_) async => oversized,
    );

    final result = await service.selectFromGallery();

    expect(await oversized.length(), 5000001);
    expect(result.status, CameraServiceStatus.invalidImage);
    expect(result.message, contains('5 MB'));
  });

  test('rejects formats other than JPEG and PNG', () async {
    final gif = XFile.fromData(
      Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]),
      name: 'medicine.gif',
    );
    final service = CameraService(imageSelectionFunction: (_) async => gif);

    final result = await service.selectFromGallery();

    expect(result.status, CameraServiceStatus.invalidImage);
    expect(result.message, contains('JPEG or PNG'));
  });

  test('converts picker failures to a clear error result', () async {
    final service = CameraService(
      imageSelectionFunction: (_) async =>
          throw PlatformException(code: 'picker_unavailable'),
    );

    final result = await service.selectFromGallery();

    expect(result.status, CameraServiceStatus.error);
    expect(result.message, isNotEmpty);
  });
}
