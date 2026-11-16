import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/curl_parser.dart';
import '../providers/request_provider.dart';

class CurlImportDialog extends StatefulWidget {
  const CurlImportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const CurlImportDialog(),
    );
  }

  @override
  State<CurlImportDialog> createState() => _CurlImportDialogState();
}

class _CurlImportDialogState extends State<CurlImportDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _import() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please paste a cURL command.';
      });
      return;
    }

    try {
      final parsedRequest = CurlParser.parse(text);
      if (parsedRequest.url.isEmpty) {
        setState(() {
          _errorMessage = 'Could not find a valid URL in the cURL command.';
        });
        return;
      }

      context.read<RequestProvider>().loadRequest(parsedRequest);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Imported ${parsedRequest.method.name} ${parsedRequest.url}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to parse cURL: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.terminal_rounded, size: 22),
          SizedBox(width: 8),
          Text('Import from cURL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a raw cURL command below to import the request:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  hintText: "curl -X POST 'https://api.example.com/v1/users' \\\n  -H 'Content-Type: application/json' \\\n  -d '{\"name\": \"Alice\"}'",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _import,
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: const Text('Import Request'),
        ),
      ],
    );
  }
}
