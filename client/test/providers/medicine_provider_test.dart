import 'dart:async';
import 'dart:typed_data';

import 'package:arogyavani/models/medicine_lookup_model.dart';
import 'package:arogyavani/providers/medicine_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  final image = XFile.fromData(
    Uint8List.fromList([1, 2, 3]),
    name: 'medicine.jpg',
  );
  final lookup = MedicineLookupModel(
    identifiedMedicine: 'Example medicine',
    confidence: 0.95,
    medicineInfo: const {'use': 'Example use'},
    disclaimer: 'For identification only.',
  );

  test('starts with empty and idle state', () {
    final provider = MedicineProvider();
    addTearDown(provider.dispose);

    expect(provider.selectedImage, isNull);
    expect(provider.result, isNull);
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
    expect(provider.hasError, isFalse);
    expect(provider.isSuccess, isFalse);
  });

  test('selecting an image stores it and clears previous lookup state', () {
    final provider = MedicineProvider();
    addTearDown(provider.dispose);
    provider.selectImage(image);

    expect(provider.selectedImage, same(image));
    expect(provider.result, isNull);
    expect(provider.errorMessage, isNull);
  });

  test('notifies listeners while identification is loading', () async {
    final completer = Completer<MedicineLookupModel>();
    final provider = MedicineProvider(identify: (_) => completer.future);
    addTearDown(provider.dispose);
    provider.selectImage(image);

    final request = provider.identifyMedicine();

    expect(provider.isLoading, isTrue);
    completer.complete(lookup);
    await request;
    expect(provider.isLoading, isFalse);
  });

  test('stores a successful identification result', () async {
    final provider = MedicineProvider(identify: (_) async => lookup);
    addTearDown(provider.dispose);
    provider.selectImage(image);

    await provider.identifyMedicine();

    expect(provider.result, same(lookup));
    expect(provider.isSuccess, isTrue);
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('stores failures as error state without throwing', () async {
    final provider = MedicineProvider(
      identify: (_) async => throw Exception('private details'),
    );
    addTearDown(provider.dispose);
    provider.selectImage(image);

    await expectLater(provider.identifyMedicine(), completes);

    expect(provider.result, isNull);
    expect(provider.hasError, isTrue);
    expect(provider.errorMessage, contains('try again'));
    expect(provider.isLoading, isFalse);
  });

  test('reset clears the image, result, error, and loading state', () async {
    final provider = MedicineProvider(identify: (_) async => lookup);
    addTearDown(provider.dispose);
    provider.selectImage(image);
    await provider.identifyMedicine();

    provider.reset();

    expect(provider.selectedImage, isNull);
    expect(provider.result, isNull);
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
    expect(provider.isSuccess, isFalse);
  });

  test('ignores duplicate identification requests while loading', () async {
    final completer = Completer<MedicineLookupModel>();
    var callCount = 0;
    final provider = MedicineProvider(
      identify: (_) {
        callCount++;
        return completer.future;
      },
    );
    addTearDown(provider.dispose);
    provider.selectImage(image);

    final firstRequest = provider.identifyMedicine();
    final duplicateRequest = provider.identifyMedicine();

    expect(callCount, 1);
    expect(provider.isLoading, isTrue);
    completer.complete(lookup);
    await Future.wait([firstRequest, duplicateRequest]);

    expect(callCount, 1);
    expect(provider.result, same(lookup));
  });
}
