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

class _KeyValueListState extends State<KeyValueList> {
  late List<MapEntry<String, String>> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.data.entries.toList();
    if (_items.isEmpty) {
      _items.add(const MapEntry('', ''));
    }
  }

  void _updateData() {
    final newData = <String, String>{};
    for (var item in _items) {
      if (item.key.isNotEmpty) {
        newData[item.key] = item.value;
      }
    }
    widget.onChanged(newData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF000000), // Keep slight grey for surface separation
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFF111111), width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
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
                                  .withOpacity(0.4)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                        controller:
                            TextEditingController(text: _items[index].key)
                              ..selection = TextSelection.collapsed(
                                  offset: _items[index].key.length),
                        onChanged: (value) {
                          _items[index] = MapEntry(value, _items[index].value);
                          _updateData();
                        },
                      ),
                    ),
                    Container(
                        width: 1.5,
                        height: 24,
                        color: Theme.of(context).dividerColor),
                    Expanded(
                      flex: 3,
                      child: TextField(
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
                                  .withOpacity(0.4)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                        controller:
                            TextEditingController(text: _items[index].value)
                              ..selection = TextSelection.collapsed(
                                  offset: _items[index].value.length),
                        onChanged: (value) {
                          _items[index] = MapEntry(_items[index].key, value);
                          _updateData();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFFF38BA8), size: 18),
                      onPressed: () {
                        setState(() {
                          _items.removeAt(index);
                          if (_items.isEmpty)
                            _items.add(const MapEntry('', ''));
                          _updateData();
                        });
                      },
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
            onPressed: () {
              setState(() {
                _items.add(const MapEntry('', ''));
              });
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Row'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFCBA6F7),
              side: const BorderSide(color: Color(0xFFCBA6F7)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
      ],
    );
  }
}
