import 'dart:typed_data';

import 'package:arogyavani/widgets/medicine/camera_viewfinder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  // A valid 1x1 transparent PNG, sufficient for exercising Image.memory.
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

  Widget createSubject({XFile? selectedImage}) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CameraViewfinder(image: selectedImage),
        ),
      ),
    );
  }

  testWidgets('shows a clear placeholder when no image is selected', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());

    expect(find.text('No medicine image selected'), findsOneWidget);
    expect(
      find.text('Choose or take a clear photo of the medicine package.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('displays the selected image', (tester) async {
    await tester.pumpWidget(createSubject(selectedImage: image));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('selected-medicine-image')),
      findsOneWidget,
    );
    expect(find.text('No medicine image selected'), findsNothing);
    final semantics = tester.getSemantics(find.byType(CameraViewfinder));
    expect(semantics.label, contains('Selected medicine image preview'));
  });

  testWidgets('renders within a narrow screen with visible frame', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSubject());

    expect(tester.takeException(), isNull);
    final frame = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(CameraViewfinder),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = frame.decoration! as BoxDecoration;
    expect(decoration.border!.dimensions.horizontal, 4);
    expect(find.text('No medicine image selected'), findsOneWidget);
  });
}
