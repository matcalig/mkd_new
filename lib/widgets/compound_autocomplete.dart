import 'dart:async';

import 'package:flutter/material.dart';

import '../models/compound.dart';
import '../services/mks_api_service.dart';

/// An autocomplete text field that searches for chemical compounds via the
/// MKS API with 300 ms debouncing and local caching.
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
  Timer? _debounce;
  DateTime _lastCallTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Returns an async iterable of matching compounds, debounced by 300 ms.
  Future<Iterable<Compound>> _optionsBuilder(
    TextEditingValue textEditingValue,
  ) async {
    final query = textEditingValue.text.trim();
    if (query.length < 2) return const [];

    // Record the time of this call for debounce comparison.
    final callTime = DateTime.now();
    _lastCallTime = callTime;

    // Wait for the debounce window.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Bail out if a newer call has arrived.
    if (callTime != _lastCallTime) return const [];

    try {
      return await widget.service.getEntities(query);
    } catch (_) {
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
            hintText: 'Type at least 2 characters…',
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      onSelected: widget.onSelected,
    );
  }
}
