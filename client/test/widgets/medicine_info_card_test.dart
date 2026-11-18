import 'package:arogyavani/widgets/medicine/medicine_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createSubject(Map<String, dynamic> info) {
    return MaterialApp(
      home: Scaffold(
        body: MedicineInfoCard(medicineInfo: info),
      ),
    );
  }

  testWidgets('renders available medicine information', (tester) async {
    await tester.pumpWidget(createSubject({
      'name': 'Acetaminophen',
      'strength': '500 mg',
      'description': 'Pain reliever',
    }));

    expect(find.text('Medicine information'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Acetaminophen'), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('500 mg'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Pain reliever'), findsOneWidget);
  });

  testWidgets('omits missing, null, and blank values', (tester) async {
    await tester.pumpWidget(createSubject({
      'name': 'Example medicine',
      'manufacturer': null,
      'description': '   ',
    }));

    expect(find.text('Example medicine'), findsOneWidget);
    expect(find.text('Manufacturer'), findsNothing);
    expect(find.text('Description'), findsNothing);
    expect(find.text('No medicine information available.'), findsNothing);
  });

  testWidgets('shows a clear empty state for empty medicine information',
      (tester) async {
    await tester.pumpWidget(createSubject(const {}));

    expect(find.text('No medicine information available.'), findsOneWidget);
  });

  testWidgets('renders nested information', (tester) async {
    await tester.pumpWidget(createSubject({
      'manufacturer': {
        'name': 'Example Pharma',
        'country': 'India',
      },
    }));

    expect(find.text('Manufacturer'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Example Pharma'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('India'), findsOneWidget);
  });

  testWidgets('uses readable, high-contrast text sizing', (tester) async {
    await tester.pumpWidget(createSubject({'name': 'Example medicine'}));

    final title = tester.widget<Text>(find.text('Medicine information'));
    final value = tester.widget<Text>(find.text('Example medicine'));
    expect(title.style!.fontSize, greaterThanOrEqualTo(20));
    expect(value.style!.fontSize, greaterThanOrEqualTo(18));
    expect(title.style!.color, const Color(0xFF102A43));
    expect(value.style!.color, const Color(0xFF102A43));
    expect(find.byType(Semantics), findsWidgets);
  });
}
