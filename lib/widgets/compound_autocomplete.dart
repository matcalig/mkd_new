import 'dart:async';

import 'package:flutter/material.dart';

import '../models/compound.dart';
import '../services/mks_api_service.dart';

/// A search field that queries chemical compounds via the MKS API.
///
/// Triggers after 3 characters with a 300 ms debounce. Suggestions appear
/// inline below the field. Selecting an item calls [onSelected].
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
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  int _token = 0;
  List<Compound> _options = [];
  bool _showOptions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Small delay so a tap on an option fires before we hide the list.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showOptions = false);
        }
      });
    }
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query.length < 3) {
      setState(() {
        _options = [];
        _showOptions = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _fetch(query),
    );
  }

  Future<void> _fetch(String query) async {
    final token = ++_token;
    try {
      final results = await widget.service.getEntities(query);
      if (token != _token || !mounted) return;
      setState(() {
        _options = results.toList();
        _showOptions = _options.isNotEmpty;
      });
    } catch (e) {
      if (token != _token || !mounted) return;
      debugPrint('CompoundAutocomplete error: $e');
      setState(() {
        _options = [];
        _showOptions = false;
      });
    }
  }

  void _onSelect(Compound compound) {
    _controller.text = compound.identifier;
    setState(() {
      _options = [];
      _showOptions = false;
    });
    _focusNode.unfocus();
    widget.onSelected(compound);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            hintText: 'Type at least 3 characters…',
          ),
          onChanged: _onChanged,
        ),
        if (_showOptions)
          Material(
            elevation: 4,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(4),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _options.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(_options[i].identifier),
                  dense: true,
                  onTap: () => _onSelect(_options[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
