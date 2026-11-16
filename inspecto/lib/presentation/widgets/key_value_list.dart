import 'package:flutter/material.dart';

class KeyValueList extends StatefulWidget {
  final String title;
  final Map<String, String> data;
  final Function(Map<String, String>) onChanged;

  const KeyValueList({
    super.key,
    required this.title,
    required this.data,
    required this.onChanged,
  });

  @override
  State<KeyValueList> createState() => _KeyValueListState();
}

class _KeyValueRowControllers {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _KeyValueRowControllers({String key = '', String value = ''})
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _KeyValueListState extends State<KeyValueList> {
  final List<_KeyValueRowControllers> _rowControllers = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    if (widget.data.isEmpty) {
      _rowControllers.add(_KeyValueRowControllers());
    } else {
      widget.data.forEach((key, value) {
        _rowControllers.add(_KeyValueRowControllers(key: key, value: value));
      });
    }
  }

  @override
  void didUpdateWidget(KeyValueList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasDataChanged(oldWidget.data, widget.data)) {
      for (final row in _rowControllers) {
        row.dispose();
      }
      _rowControllers.clear();
      _initControllers();
    }
  }

  bool _hasDataChanged(Map<String, String> oldData, Map<String, String> newData) {
    if (oldData.length != newData.length) return true;
    for (final entry in oldData.entries) {
      if (newData[entry.key] != entry.value) return true;
    }
    return false;
  }

  void _updateData() {
    final newData = <String, String>{};
    for (final row in _rowControllers) {
      final key = row.keyController.text.trim();
      final val = row.valueController.text;
      if (key.isNotEmpty) {
        newData[key] = val;
      }
    }
    widget.onChanged(newData);
  }

  void _addRow() {
    setState(() {
      _rowControllers.add(_KeyValueRowControllers());
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rowControllers[index].dispose();
      _rowControllers.removeAt(index);
      if (_rowControllers.isEmpty) {
        _rowControllers.add(_KeyValueRowControllers());
      }
      _updateData();
    });
  }

  @override
  void dispose() {
    for (final row in _rowControllers) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _rowControllers.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final row = _rowControllers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: Theme.of(context).brightness == Brightness.dark
                        ? 1.5
                        : 1.0,
                  ),
                  boxShadow: Theme.of(context).brightness == Brightness.light
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: row.keyController,
                        style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Key',
                          hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                        onChanged: (_) => _updateData(),
                      ),
                    ),
                    Container(
                        width: 1.5,
                        height: 24,
                        color: Theme.of(context).dividerColor),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: row.valueController,
                        style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary),
                        decoration: InputDecoration(
                          hintText: 'Value',
                          hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.4)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                        onChanged: (_) => _updateData(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFFF38BA8), size: 18),
                      onPressed: () => _removeRow(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: OutlinedButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Row'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }
}
