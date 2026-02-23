import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/compound.dart';
import '../models/result_value.dart';

/// Client for the MKS Web Editions API.
///
/// API endpoint: https://mkswebapi.com/process?request=<url-encoded-json>
/// All requests are HTTP GET with the JSON body URL-encoded in the `request=`
/// query parameter.
class MksApiService {
  static const String _baseUrl = 'https://mkswebapi.com/process';
  static const Duration _timeout = Duration(seconds: 30);

  // Cache for entity (compound) searches keyed by lowercase name pattern.
  final Map<String, List<Compound>> _entityCache = {};

  // Cache for available properties.
  List<String>? _propertiesCache;

  /// Sends a JSON request to the API and returns the decoded response map.
  Future<Map<String, dynamic>> _request(Map<String, dynamic> body) async {
    final encoded = Uri.encodeComponent(json.encode(body));
    final uri = Uri.parse('$_baseUrl?request=$encoded');

    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception(
          'API request failed (HTTP ${response.statusCode}). '
          'Check your network connection and try again.',
        );
      }
      return json.decode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on FormatException catch (e) {
      throw Exception('Invalid response format: $e');
    }
  }

  /// Sends a "Hello" request and returns true if the API is reachable.
  Future<bool> hello() async {
    final result = await _request({'Type': 'Hello'});
    return result['API'] == 'Running';
  }

  /// Searches for chemicals whose names match [namePattern].
  ///
  /// Results are cached for the lifetime of the service instance.
  Future<List<Compound>> getEntities(String namePattern) async {
    final pattern = namePattern.trim();
    if (pattern.isEmpty) return const [];

    final key = pattern.toLowerCase();
    if (_entityCache.containsKey(key)) return _entityCache[key]!;

    final result = await _request({
      'Type': 'Get Entities',
      'Arguments': {
        'EntityType': 'Chemical',
        'NamePattern': pattern,
      },
    });

    final raw = result['Entities'] as List<dynamic>? ?? const [];
    final entities =
        raw
            .whereType<Map<String, dynamic>>()
            .map(Compound.fromJson)
            .where((c) => c.identifier.isNotEmpty)
            .toList();

    _entityCache[key] = entities;
    return entities;
  }

  /// Returns the list of available thermodynamic / physical property names.
  ///
  /// Results are cached after the first successful call.
  Future<List<String>> getProperties() async {
    if (_propertiesCache != null) return _propertiesCache!;

    final result = await _request({
      'Type': 'Get Properties',
      'Arguments': {'EntityType': 'Chemical'},
    });

    final raw = result['Properties'] as List<dynamic>? ?? const [];
    final names =
        raw
            .map((p) {
              if (p is Map<String, dynamic>) return p['Name'] as String? ?? '';
              if (p is String) return p;
              return '';
            })
            .where((n) => n.isNotEmpty)
            .toList();

    _propertiesCache = names;
    return names;
  }

  /// Queries the API for [properties] of [compounds] at the given
  /// [temperature] (K) and [pressure] (kPa).
  ///
  /// Internally issues one "Get Values" request per compound so that results
  /// for each compound are clearly separated.
  Future<List<ResultValue>> getValues({
    required List<Compound> compounds,
    required List<String> properties,
    required double temperature,
    required double pressure,
  }) async {
    final results = <ResultValue>[];

    for (final compound in compounds) {
      final response = await _request({
        'Type': 'Get Values',
        'Arguments': {
          'EntityType': compound.entityType,
          'Identifier': compound.identifier,
          'Properties': properties,
          'Temperature': {
            'Value': temperature.toString(),
            'Units': 'K',
          },
          'Pressure': {
            'Value': pressure.toString(),
            'Units': 'kPa',
          },
        },
      });

      final entities =
          (response['Entities'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>();

      for (final entity in entities) {
        final entityId =
            entity['Identifier'] as String? ?? compound.identifier;
        final entityProps =
            (entity['Properties'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>();

        for (final prop in entityProps) {
          final propName = prop['Name'] as String? ?? '';
          final status = prop['Status'] as String? ?? '';
          final data =
              (prop['Data'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>();

          if (data.isEmpty) {
            results.add(
              ResultValue(
                compound: entityId,
                property: propName,
                status: status,
                value: 'N/A',
                units: '',
              ),
            );
          } else {
            for (final point in data) {
              results.add(
                ResultValue(
                  compound: entityId,
                  property: propName,
                  status: status,
                  value: point['Value'] as String? ?? '',
                  units: point['ValueUnits'] as String? ?? '',
                  reference: point['Reference'] as String? ?? '',
                ),
              );
            }
          }
        }
      }
    }

    return results;
  }
}
