// Basic app boot smoke test.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youmatter_mobile/main.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    // Build our app and trigger a frame. Auth status loads asynchronously from
    // secure storage (unavailable in the test env), which resolves to a
    // signed-out state and points the router at the welcome screen.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pump();

    // The app should be running and render a MaterialApp (either the initial
    // splash or the router once auth status has resolved).
    expect(find.byType(MaterialApp), findsWidgets);
  });
}