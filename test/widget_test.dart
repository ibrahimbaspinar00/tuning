// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:tuning_web/main.dart';

void main() {
  testWidgets('App loads and displays landing page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TuningWebApp());

    // Wait for the widget tree to settle
    await tester.pumpAndSettle();

    // Verify that the landing page title is displayed
    expect(find.text('tuning.'), findsOneWidget);
    expect(find.text('Otomobil Tuning Dünyasına Hoş Geldiniz'), findsOneWidget);
  });
}
