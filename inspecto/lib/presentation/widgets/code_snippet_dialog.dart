import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../../core/utils/code_generator.dart';
import '../../domain/entities/api_request.dart';

class CodeSnippetDialog extends StatefulWidget {
  final ApiRequest request;

  const CodeSnippetDialog({super.key, required this.request});

  static Future<void> show(BuildContext context, ApiRequest request) {
    return showDialog(
      context: context,
      builder: (_) => CodeSnippetDialog(request: request),
    );
  }

  @override
  State<CodeSnippetDialog> createState() => _CodeSnippetDialogState();
}

class _CodeSnippetDialogState extends State<CodeSnippetDialog> {
  CodeLanguage _selectedLanguage = CodeLanguage.curl;

  final Map<CodeLanguage, String> _languageNames = {
    CodeLanguage.curl: 'cURL',
    CodeLanguage.dartHttp: 'Dart (http)',
    CodeLanguage.dartDio: 'Dart (dio)',
    CodeLanguage.jsFetch: 'JavaScript (fetch)',
    CodeLanguage.nodeAxios: 'Node.js (axios)',
    CodeLanguage.pythonRequests: 'Python (requests)',
    CodeLanguage.pythonHttpx: 'Python (httpx)',
    CodeLanguage.go: 'Go (net/http)',
  };

  final Map<CodeLanguage, String> _highlightLangs = {
    CodeLanguage.curl: 'bash',
    CodeLanguage.dartHttp: 'dart',
    CodeLanguage.dartDio: 'dart',
    CodeLanguage.jsFetch: 'javascript',
    CodeLanguage.nodeAxios: 'javascript',
    CodeLanguage.pythonRequests: 'python',
    CodeLanguage.pythonHttpx: 'python',
    CodeLanguage.go: 'go',
  };

  @override
  Widget build(BuildContext context) {
    final generatedCode =
        CodeGenerator.generate(widget.request, _selectedLanguage);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.code_rounded, size: 22),
              SizedBox(width: 8),
              Text('Generate Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CodeLanguage.values.map((lang) {
                  final isSelected = _selectedLanguage == lang;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_languageNames[lang]!),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedLanguage = lang),
                      selectedColor:
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: HighlightView(
                    generatedCode,
                    language: _highlightLangs[_selectedLanguage] ?? 'plaintext',
                    theme: atomOneDarkTheme,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: generatedCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Code snippet copied to clipboard!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy Snippet'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
