import 'package:flutter/material.dart';

import '../models/result_value.dart';

/// Displays the API results in a scrollable data table.
///
/// Shows three possible states:
///  - [isLoading] is true  → spinner
///  - [errorMessage] is set → error text
///  - otherwise             → table (or "no data" message)
class ResultsTable extends StatelessWidget {
  const ResultsTable({
    super.key,
    required this.results,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ResultValue> results;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: $errorMessage',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No results returned.'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Compound')),
          DataColumn(label: Text('Property')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Value')),
          DataColumn(label: Text('Units')),
        ],
        rows:
            results
                .map(
                  (r) => DataRow(
                    cells: [
                      DataCell(Text(r.compound)),
                      DataCell(Text(r.property)),
                      DataCell(Text(r.status)),
                      DataCell(Text(r.value)),
                      DataCell(Text(r.units)),
                    ],
                  ),
                )
                .toList(),
      ),
    );
  }
}
