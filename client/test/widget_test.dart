import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arogyavani/main.dart';

void main() {
  testWidgets('MyApp displays ArogyaVaani', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ArogyaVaani'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
