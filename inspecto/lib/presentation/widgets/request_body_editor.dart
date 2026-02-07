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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildTypeChip(context, 'none', 'No Body'),
              const SizedBox(width: 8),
              _buildTypeChip(context, 'json', 'JSON'),
              const SizedBox(width: 8),
              _buildTypeChip(context, 'form', 'Form Data'),
            ],
          ),
        ),
        if (provider.bodyType != 'none')
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                ),
                child: Stack(
                  children: [
                    TextField(
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.transparent, // Hide text to show highlighting
                      ),
                      cursorColor: Colors.white,
                      decoration: const InputDecoration(
                        hintText: 'Enter request body...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                      ),
                      onChanged: (value) => provider.setBody(value),
                    ),
                    if (provider.bodyType == 'json' && provider.body != null)
                      IgnorePointer(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: HighlightView(
                            provider.body!,
                            language: 'json',
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
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      showCheckmark: false,
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF1A1A1A),
      ),
    );
  }
}
