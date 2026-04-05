import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('Shizuki app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShizukiApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
