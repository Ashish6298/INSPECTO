import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../providers/request_provider.dart';

class RequestBodyEditor extends StatelessWidget {
  const RequestBodyEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();

    return Column(
      children: [
        // Horizontal Scrollable Body Type Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildTypeChip(context, 'none', 'none'),
              const SizedBox(width: 8),
              _buildTypeChip(context, 'form-data', 'form-data'),
              const SizedBox(width: 8),
              _buildTypeChip(
                  context, 'x-www-form-urlencoded', 'x-www-form-urlencoded'),
              const SizedBox(width: 8),
              _buildTypeRow(context, 'raw', 'raw'),
              const SizedBox(width: 8),
              _buildTypeChip(context, 'binary', 'binary'),
              const SizedBox(width: 8),
              _buildTypeChip(context, 'graphql', 'GraphQL'),
            ],
          ),
        ),

        // Body Editor Area
        if (provider.bodyType != 'none')
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Theme.of(context).dividerColor, width: 1.5),
                ),
                child: Stack(
                  children: [
                    TextField(
                      maxLines: null,
                      expands: true,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: _shouldHighlight(provider.bodyType)
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      cursorColor: Theme.of(context).colorScheme.primary,
                      decoration: InputDecoration(
                        hintText: 'Enter request body...',
                        hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                        fillColor: Colors.transparent,
                      ),
                      onChanged: (value) => provider.setBody(value),
                    ),
                    if (_shouldHighlight(provider.bodyType) &&
                        provider.body != null)
                      IgnorePointer(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: HighlightView(
                            provider.body!,
                            language: provider.bodyType == 'graphql'
                                ? 'json'
                                : provider.bodySubType,
                            theme: atomOneDarkTheme,
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(
                                fontFamily: 'monospace', fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (provider.bodyType == 'none')
          Expanded(
            child: Center(
              child: Text(
                'THIS REQUEST DOES NOT HAVE A BODY',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _shouldHighlight(String type) {
    return type == 'json' || type == 'raw' || type == 'graphql';
  }

  Widget _buildTypeChip(BuildContext context, String value, String label) {
    final provider = context.read<RequestProvider>();
    final isSelected = provider.bodyType == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setBodyType(value),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      ),
      showCheckmark: false,
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).dividerColor,
      ),
    );
  }

  Widget _buildTypeRow(BuildContext context, String value, String label) {
    final provider = context.watch<RequestProvider>();
    final isSelected = provider.bodyType == value;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => provider.setBodyType(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ),
        ),
        if (isSelected) ...[
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: provider.bodySubType,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 16),
            items: ['text', 'json', 'javascript', 'html', 'xml']
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.toUpperCase(),
                          style: const TextStyle(fontSize: 11)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) provider.setBodySubType(val);
            },
          ),
        ],
      ],
    );
  }
}

