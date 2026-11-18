import 'dart:async';
import 'dart:typed_data';

import 'package:arogyavani/models/medicine_lookup_model.dart';
import 'package:arogyavani/providers/medicine_provider.dart';
import 'package:arogyavani/screens/medicine/medicine_screen.dart';
import 'package:arogyavani/services/camera_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  final image = XFile.fromData(
    Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0B,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0xA5,
      0xF6,
      0x45,
      0x40,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]),
    name: 'medicine.png',
  );

  MedicineLookupModel lookup() => MedicineLookupModel(
    identifiedMedicine: 'Example medicine',
    confidence: 0.9,
    medicineInfo: const {},
    disclaimer: 'For identification only.',
  );

  Widget createSubject({
    required MedicineProvider provider,
    CameraService? cameraService,
  }) {
    return MaterialApp(
      home: MedicineScreen(provider: provider, cameraService: cameraService),
    );
  }

  testWidgets('renders the initial instructions and image placeholder', (
    tester,
  ) async {
    final provider = MedicineProvider();
    addTearDown(provider.dispose);

    await tester.pumpWidget(createSubject(provider: provider));

    expect(find.text('Medicine Vision AI'), findsOneWidget);
    expect(find.text('Identify a medicine'), findsOneWidget);
    expect(
      find.textContaining('Take a photo or choose a photo'),
      findsOneWidget,
    );
    expect(find.text('No medicine image selected'), findsOneWidget);
    expect(find.byKey(const ValueKey('open-camera')), findsOneWidget);
    expect(find.byKey(const ValueKey('open-gallery')), findsOneWidget);
  });

  testWidgets(
    'camera button invokes camera selection and shows selected image',
    (tester) async {
      ImageSource? requestedSource;
      final provider = MedicineProvider();
      addTearDown(provider.dispose);
      final service = CameraService(
        imageSelectionFunction: (source) async {
          requestedSource = source;
          return image;
        },
      );

      await tester.pumpWidget(
        createSubject(provider: provider, cameraService: service),
      );
      await tester.tap(find.byKey(const ValueKey('open-camera')));
      await tester.pumpAndSettle();

      expect(requestedSource, ImageSource.camera);
      expect(provider.selectedImage, same(image));
      expect(
        find.byKey(const ValueKey('selected-medicine-image')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('clear-medicine-image')),
        findsOneWidget,
      );
    },
  );

  testWidgets('gallery button invokes gallery selection', (tester) async {
    ImageSource? requestedSource;
    final provider = MedicineProvider();
    addTearDown(provider.dispose);
    final service = CameraService(
      imageSelectionFunction: (source) async {
        requestedSource = source;
        return image;
      },
    );

    await tester.pumpWidget(
      createSubject(provider: provider, cameraService: service),
    );
    await tester.tap(find.byKey(const ValueKey('open-gallery')));
    await tester.pumpAndSettle();

    expect(requestedSource, ImageSource.gallery);
    expect(provider.selectedImage, same(image));
    expect(
      find.byKey(const ValueKey('selected-medicine-image')),
      findsOneWidget,
    );
  });

  testWidgets('shows a selected image supplied by the provider', (
    tester,
  ) async {
    final provider = MedicineProvider()..selectImage(image);
    addTearDown(provider.dispose);

    await tester.pumpWidget(createSubject(provider: provider));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('selected-medicine-image')),
      findsOneWidget,
    );
    expect(find.text('Clear selected image'), findsOneWidget);
  });

  testWidgets('shows loading state from the provider', (tester) async {
    final completer = Completer<MedicineLookupModel>();
    final provider = MedicineProvider(identify: (_) => completer.future)
      ..selectImage(image);
    addTearDown(provider.dispose);
    await tester.pumpWidget(createSubject(provider: provider));

    final request = provider.identifyMedicine();
    await tester.pump();

    expect(find.text('Working on your request…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    completer.complete(lookup());
    await request;
    await tester.pump();
  });

  testWidgets('shows and dismisses provider error state', (tester) async {
    final provider = MedicineProvider(
      identify: (_) async => throw Exception('test error'),
    )..selectImage(image);
    addTearDown(provider.dispose);
    await tester.pumpWidget(createSubject(provider: provider));

    await provider.identifyMedicine();
    await tester.pump();

    expect(
      find.text('Could not identify this medicine. Please try again.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Dismiss'));
    await tester.pump();
    await tester.tap(find.text('Dismiss'));
    await tester.pump();
    expect(
      find.text('Could not identify this medicine. Please try again.'),
      findsNothing,
    );
  });
}
