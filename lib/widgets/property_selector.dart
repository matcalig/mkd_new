import 'package:flutter/material.dart';

const int _maxProperties = 5;

/// A multi-select widget for choosing up to [_maxProperties] thermodynamic
/// / physical property names.
///
/// [availableProperties] is the list fetched from the API.
/// [selectedProperties] holds the currently selected names.
/// [onChanged] is called whenever the selection changes.
class PropertySelector extends StatelessWidget {
  const PropertySelector({
    super.key,
    required this.availableProperties,
    required this.selectedProperties,
    required this.onChanged,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<String> availableProperties;
  final List<String> selectedProperties;
  final ValueChanged<List<String>> onChanged;
  final bool isLoading;
  final String? errorMessage;

  void _toggle(String name) {
    final updated = List<String>.from(selectedProperties);
    if (updated.contains(name)) {
      updated.remove(name);
    } else if (updated.length < _maxProperties) {
      updated.add(name);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Loading properties…'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Text(
        'Could not load properties: $errorMessage',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    if (availableProperties.isEmpty) {
      return const Text('No properties available.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Properties (select up to $_maxProperties)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children:
              availableProperties.map((name) {
                final isSelected = selectedProperties.contains(name);
                final atMax =
                    !isSelected && selectedProperties.length >= _maxProperties;
                return FilterChip(
                  label: Text(name),
                  selected: isSelected,
                  onSelected: atMax ? null : (_) => _toggle(name),
                );
              }).toList(),
        ),
      ],
    );
  }
}
