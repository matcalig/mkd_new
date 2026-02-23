import 'package:flutter/material.dart';

import 'models/compound.dart';
import 'models/result_value.dart';
import 'services/mks_api_service.dart';
import 'widgets/compound_autocomplete.dart';
import 'widgets/property_selector.dart';
import 'widgets/results_table.dart';

void main() {
  runApp(const ThermoApp());
}

class ThermoApp extends StatelessWidget {
  const ThermoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thermo Data Explorer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ThermoDataExplorer(),
    );
  }
}

class ThermoDataExplorer extends StatefulWidget {
  const ThermoDataExplorer({super.key});

  @override
  State<ThermoDataExplorer> createState() => _ThermoDataExplorerState();
}

class _ThermoDataExplorerState extends State<ThermoDataExplorer> {
  final MksApiService _api = MksApiService();

  // --- compound selection ---
  Compound? _compound1;
  Compound? _compound2;

  // --- property selection ---
  List<String> _availableProperties = [];
  List<String> _selectedProperties = [];
  bool _loadingProperties = false;
  String? _propertiesError;

  // --- conditions ---
  final TextEditingController _tempController = TextEditingController(
    text: '293.15',
  );
  final TextEditingController _pressureController = TextEditingController(
    text: '101.325',
  );
  String? _tempError;
  String? _pressureError;

  // --- results ---
  List<ResultValue> _results = [];
  bool _calculating = false;
  bool _hasQueried = false;
  String? _resultsError;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _tempController.dispose();
    _pressureController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _loadingProperties = true;
      _propertiesError = null;
    });
    try {
      final props = await _api.getProperties();
      if (mounted) {
        setState(() {
          _availableProperties = props;
          _loadingProperties = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _propertiesError = e.toString();
          _loadingProperties = false;
        });
      }
    }
  }

  // --- validation ---

  String? _validateDouble(String value, String fieldName) {
    if (value.trim().isEmpty) return '$fieldName is required.';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return '$fieldName must be a number.';
    if (parsed <= 0) return '$fieldName must be positive.';
    return null;
  }

  bool get _isFormValid {
    if (_compound1 == null) return false;
    if (_selectedProperties.isEmpty) return false;
    if (_validateDouble(_tempController.text, 'Temperature') != null) {
      return false;
    }
    if (_validateDouble(_pressureController.text, 'Pressure') != null) {
      return false;
    }
    return true;
  }

  void _onTempChanged(String _) {
    setState(() {
      _tempError = _validateDouble(_tempController.text, 'Temperature');
    });
  }

  void _onPressureChanged(String _) {
    setState(() {
      _pressureError = _validateDouble(
        _pressureController.text,
        'Pressure',
      );
    });
  }

  // --- calculate ---

  Future<void> _calculate() async {
    final tempErr = _validateDouble(_tempController.text, 'Temperature');
    final pressErr = _validateDouble(_pressureController.text, 'Pressure');
    setState(() {
      _tempError = tempErr;
      _pressureError = pressErr;
    });
    if (tempErr != null || pressErr != null) return;

    final compounds = [_compound1!, if (_compound2 != null) _compound2!];
    final temperature = double.parse(_tempController.text.trim());
    final pressure = double.parse(_pressureController.text.trim());

    setState(() {
      _calculating = true;
      _hasQueried = true;
      _resultsError = null;
      _results = [];
    });

    try {
      final values = await _api.getValues(
        compounds: compounds,
        properties: _selectedProperties,
        temperature: temperature,
        pressure: pressure,
      );
      if (mounted) {
        setState(() {
          _results = values;
          _calculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultsError = e.toString();
          _calculating = false;
        });
      }
    }
  }

  // --- build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Thermo Data Explorer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Compounds ----
                Text(
                  'Compounds',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                CompoundAutocomplete(
                  key: const ValueKey('compound1'),
                  label: 'Compound 1 (required)',
                  service: _api,
                  onSelected: (c) => setState(() => _compound1 = c),
                ),
                const SizedBox(height: 12),
                CompoundAutocomplete(
                  key: const ValueKey('compound2'),
                  label: 'Compound 2 (optional)',
                  service: _api,
                  onSelected: (c) => setState(() => _compound2 = c),
                ),
                const SizedBox(height: 20),

                // ---- Properties ----
                Text(
                  'Properties',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                PropertySelector(
                  availableProperties: _availableProperties,
                  selectedProperties: _selectedProperties,
                  isLoading: _loadingProperties,
                  errorMessage: _propertiesError,
                  onChanged: (updated) {
                    setState(() => _selectedProperties = updated);
                  },
                ),
                const SizedBox(height: 20),

                // ---- Conditions ----
                Text(
                  'Operating Conditions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tempController,
                        decoration: InputDecoration(
                          labelText: 'Temperature (K)',
                          border: const OutlineInputBorder(),
                          errorText: _tempError,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: _onTempChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _pressureController,
                        decoration: InputDecoration(
                          labelText: 'Pressure (kPa)',
                          border: const OutlineInputBorder(),
                          errorText: _pressureError,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: _onPressureChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ---- Calculate Button ----
                ElevatedButton.icon(
                  onPressed:
                      (_isFormValid && !_calculating) ? _calculate : null,
                  icon:
                      _calculating
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.calculate),
                  label: const Text('Calculate'),
                ),
                const SizedBox(height: 24),

                // ---- Results ----
                if (_hasQueried) ...[
                  const Divider(),
                  Text(
                    'Results',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ResultsTable(
                    results: _results,
                    isLoading: _calculating,
                    errorMessage: _resultsError,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
