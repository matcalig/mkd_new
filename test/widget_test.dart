// Tests for the Thermo Data Explorer app.
//
// The MksApiService constructor accepts an optional http.Client so that tests
// can supply a MockClient that returns canned responses without hitting the
// real network.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mkd_new/main.dart';
import 'package:mkd_new/services/mks_api_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a [MockClient] whose responses match the 'Type' field of the
/// JSON-encoded `request=` query parameter.
MockClient _makeMockClient({
  List<Map<String, dynamic>> properties = const [],
  List<Map<String, dynamic>> entities = const [],
  List<Map<String, dynamic>> valueEntities = const [],
}) {
  return MockClient((request) async {
    final raw = request.url.queryParameters['request'] ?? '{}';
    final body = json.decode(Uri.decodeComponent(raw)) as Map<String, dynamic>;
    final type = body['Type'] as String? ?? '';

    switch (type) {
      case 'Hello':
        return http.Response(json.encode({'API': 'Running'}), 200);
      case 'Get Properties':
        return http.Response(json.encode({'Properties': properties}), 200);
      case 'Get Entities':
        return http.Response(json.encode({'Entities': entities}), 200);
      case 'Get Values':
        return http.Response(json.encode({'Entities': valueEntities}), 200);
      default:
        return http.Response('{}', 200);
    }
  });
}

/// Builds a [ThermoDataExplorer] wired to the given [client].
Widget _buildApp(http.Client client) {
  final service = MksApiService(client: client);
  return MaterialApp(
    home: ThermoDataExplorer(service: service),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('App renders title and form fields', (tester) async {
    final client = _makeMockClient();
    await tester.pumpWidget(_buildApp(client));
    await tester.pumpAndSettle();

    expect(find.text('Thermo Data Explorer'), findsOneWidget);
    expect(find.text('Compounds'), findsOneWidget);
    expect(find.text('Operating Conditions'), findsOneWidget);
    expect(find.text('Calculate'), findsOneWidget);
  });

  testWidgets('Calculate button is disabled when no compound is selected',
      (tester) async {
    final client = _makeMockClient(
      properties: [
        {'Name': 'Density'},
      ],
    );
    await tester.pumpWidget(_buildApp(client));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Calculate'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Property chips appear after properties load', (tester) async {
    final client = _makeMockClient(
      properties: [
        {'Name': 'Density'},
        {'Name': 'Viscosity'},
      ],
    );
    await tester.pumpWidget(_buildApp(client));
    await tester.pumpAndSettle();

    expect(find.text('Density'), findsOneWidget);
    expect(find.text('Viscosity'), findsOneWidget);
  });

  testWidgets('Shows error when properties fail to load', (tester) async {
    final client = MockClient((_) async => http.Response('bad json', 500));
    await tester.pumpWidget(_buildApp(client));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not load properties'), findsOneWidget);
  });

  testWidgets('Temperature validation rejects non-numeric input',
      (tester) async {
    final client = _makeMockClient();
    await tester.pumpWidget(_buildApp(client));
    await tester.pumpAndSettle();

    final tempField = find.widgetWithText(TextField, '293.15');
    await tester.enterText(tempField, 'abc');
    await tester.pump();

    expect(find.text('Temperature must be a number.'), findsOneWidget);
  });

  testWidgets('Temperature validation rejects zero', (tester) async {
    final client = _makeMockClient();
    await tester.pumpWidget(_buildApp(client));
    await tester.pumpAndSettle();

    final tempField = find.widgetWithText(TextField, '293.15');
    await tester.enterText(tempField, '0');
    await tester.pump();

    expect(find.text('Temperature must be positive.'), findsOneWidget);
  });

  testWidgets('Pressure validation rejects empty value', (tester) async {
    final client = _makeMockClient();
    await tester.pumpWidget(_buildApp(client));
    await tester.pumpAndSettle();

    final pressureField = find.widgetWithText(TextField, '101.325');
    await tester.enterText(pressureField, '');
    await tester.pump();

    expect(find.text('Pressure is required.'), findsOneWidget);
  });

  testWidgets('MksApiService parses getValues response correctly',
      (tester) async {
    final valueEntities = [
      {
        'Identifier': 'Water',
        'Properties': [
          {
            'Name': 'Density',
            'Data': [
              {'Status': 'OK', 'Value': '997.0', 'Units': 'kg/m3'},
            ],
          },
        ],
      },
    ];
    final client = _makeMockClient(
      properties: [
        {'Name': 'Density'},
      ],
      entities: [
        {'Identifier': 'Water', 'EntityType': 'Chemical'},
      ],
      valueEntities: valueEntities,
    );

    final service = MksApiService(client: client);
    final water = (await service.getEntities('Water')).first;
    final results = await service.getValues(
      compounds: [water],
      properties: ['Density'],
      temperature: 293.15,
      pressure: 101.325,
    );

    expect(results.length, 1);
    expect(results.first.compound, 'Water');
    expect(results.first.property, 'Density');
    expect(results.first.value, '997.0');
    expect(results.first.units, 'kg/m3');
  });
}

