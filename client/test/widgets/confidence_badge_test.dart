import 'package:arogyavani/widgets/medicine/confidence_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createSubject(Object? confidence) {
    return MaterialApp(
      home: Scaffold(body: ConfidenceBadge(confidence: confidence)),
    );
  }

  testWidgets('displays valid confidence values without assigning a scale',
      (tester) async {
    await tester.pumpWidget(createSubject(0.85));

    expect(find.text('Confidence: 0.85'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('probability'), findsNothing);
  });

  testWidgets('supports integer and decimal values', (tester) async {
    await tester.pumpWidget(createSubject(1));
    expect(find.text('Confidence: 1'), findsOneWidget);

    await tester.pumpWidget(createSubject(0.375));
    expect(find.text('Confidence: 0.375'), findsOneWidget);
  });

  testWidgets('handles invalid values safely', (tester) async {
    await tester.pumpWidget(createSubject('unknown'));

    expect(find.text('Confidence: Unavailable'), findsOneWidget);
  });

  testWidgets('handles non-finite values safely', (tester) async {
    for (final value in [double.nan, double.infinity, double.negativeInfinity]) {
      await tester.pumpWidget(createSubject(value));
      expect(find.text('Confidence: Unavailable'), findsOneWidget);
    }
  });

  testWidgets('uses readable, high-contrast presentation', (tester) async {
    await tester.pumpWidget(createSubject(0.8));

    final text = tester.widget<Text>(find.text('Confidence: 0.8'));
    expect(text.style!.fontSize, greaterThanOrEqualTo(18));
    expect(text.style!.fontWeight, FontWeight.w700);
    expect(text.style!.color, const Color(0xFF102A43));
    expect(find.byType(Semantics), findsWidgets);
  });
}
