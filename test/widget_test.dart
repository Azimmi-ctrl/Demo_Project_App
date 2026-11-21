
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic widget test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Cashly Campus'),
        ),
      ),
    );

    expect(find.text('Cashly Campus'), findsOneWidget);
  });
}
