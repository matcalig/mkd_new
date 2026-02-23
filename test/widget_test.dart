// Basic smoke test for the Thermo Data Explorer app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mkd_new/main.dart';

void main() {
  testWidgets('App renders title and form fields', (WidgetTester tester) async {
    await tester.pumpWidget(const ThermoApp());

    // AppBar title is present.
    expect(find.text('Thermo Data Explorer'), findsOneWidget);

    // Section headings are present.
    expect(find.text('Compounds'), findsOneWidget);
    expect(find.text('Operating Conditions'), findsOneWidget);

    // Calculate button is present (initially disabled because no compound is
    // selected and no properties are chosen).
    expect(find.text('Calculate'), findsOneWidget);
  });
}
