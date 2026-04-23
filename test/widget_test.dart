// Basic Flutter widget test for IdeaSpark app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ideaspark/main.dart';

void main() {
  testWidgets('App pumps without error', (WidgetTester tester) async {
    await tester.pumpWidget(const IdeaSparkApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
