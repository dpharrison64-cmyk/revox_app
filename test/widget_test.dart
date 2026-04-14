// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:revox_app/main.dart';

void main() {
  testWidgets('App shell displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AppSelector());

    // Verify that the app bar is present with title
    expect(find.text('Revox'), findsWidgets);
    
    // Verify navigation rail is present
    expect(find.byType(NavigationRail), findsOneWidget);
    
    // Verify home screen content is displayed
    expect(find.text('Welcome to Revox'), findsOneWidget);
  });
}

