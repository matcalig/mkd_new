import 'dart:async';

import 'package:flutter/material.dart';

import '../models/compound.dart';
import '../services/mks_api_service.dart';

/// An autocomplete text field that searches for chemical compounds via the
/// MKS API with a 3-character minimum, 300 ms debouncing, and local caching.
///
/// The [label] is displayed inside the text field.
/// When the user selects a compound, [onSelected] is called.
class CompoundAutocomplete extends StatefulWidget {
  const CompoundAutocomplete({
    super.key,
    required this.label,
    required this.service,
    required this.onSelected,
  });

  final String label;
  final MksApiService service;
  final ValueChanged<Compound?> onSelected;

  @override
  State<CompoundAutocomplete> createState() => _CompoundAutocompleteState();
}

class _CompoundAutocompleteState extends State<CompoundAutocomplete> {
  int _token = 0;

  /// Returns an async iterable of matching compounds, debounced by 300 ms.
  Future<Iterable<Compound>> _optionsBuilder(
    TextEditingValue textEditingValue,
  ) async {
    final query = textEditingValue.text.trim();
    if (query.length < 3) return const [];

    // Increment token; bail if a newer call arrives before delay expires.
    final token = ++_token;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (token != _token) return const [];

    try {
      return await widget.service.getEntities(query);
    } catch (e) {
      debugPrint('CompoundAutocomplete error: $e');
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Compound>(
      displayStringForOption: (c) => c.identifier,
      optionsBuilder: _optionsBuilder,
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            hintText: 'Type at least 3 characters…',
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      onSelected: widget.onSelected,
    );
  }
}
