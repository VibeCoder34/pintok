// PinTok widget test: app builds and shows main UI.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pintok/main.dart';

void main() {
  testWidgets('App builds and shows PinTok title', (WidgetTester tester) async {
    await tester.pumpWidget(const PinTokApp());
    await tester.pump(); // allow first frame
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PinTok'), findsOneWidget);
  });
}
