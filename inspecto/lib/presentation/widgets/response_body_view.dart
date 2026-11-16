import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../../domain/entities/api_response.dart';

class ResponseBodyView extends StatefulWidget {
  final ApiResponse response;
  final String initialFormat; // 'json' or 'raw'

  const ResponseBodyView({
    super.key,
    required this.response,
    this.initialFormat = 'json',
  });

  @override
  State<ResponseBodyView> createState() => _ResponseBodyViewState();
}

class _ResponseBodyViewState extends State<ResponseBodyView> {
  late String _currentFormat; // 'json', 'raw', 'preview'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _matchCount = 0;

  @override
  void initState() {
    super.initState();
    _currentFormat = widget.initialFormat;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getPrettyJson(String body) {
    try {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return body;
    }
  }

  bool _isJsonContentType() {
    final ct = _getContentType();
    return ct.contains('application/json') ||
        (widget.response.body.trim().startsWith('{') &&
            widget.response.body.trim().endsWith('}')) ||
        (widget.response.body.trim().startsWith('[') &&
            widget.response.body.trim().endsWith(']'));
  }

  String _getContentType() {
    for (final entry in widget.response.headers.entries) {
      if (entry.key.toLowerCase() == 'content-type') {
        return entry.value.toLowerCase();
      }
    }
    return '';
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _matchCount = 0;
      } else {
        final matches = RegExp(RegExp.escape(query), caseSensitive: false)
            .allMatches(widget.response.body);
        _matchCount = matches.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentType = _getContentType();
    final isImage = contentType.startsWith('image/');
    final isHtml = contentType.contains('text/html');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-bar: Format toggle & Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Format toggle chips
              ChoiceChip(
                label: const Text('JSON', style: TextStyle(fontSize: 11)),
                selected: _currentFormat == 'json',
                onSelected: (_) => setState(() => _currentFormat = 'json'),
                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: _currentFormat == 'json'
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: _currentFormat == 'json'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                showCheckmark: false,
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Raw', style: TextStyle(fontSize: 11)),
                selected: _currentFormat == 'raw',
                onSelected: (_) => setState(() => _currentFormat = 'raw'),
                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: _currentFormat == 'raw'
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: _currentFormat == 'raw'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                showCheckmark: false,
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Preview', style: TextStyle(fontSize: 11)),
                selected: _currentFormat == 'preview',
                onSelected: (_) => setState(() => _currentFormat = 'preview'),
                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: _currentFormat == 'preview'
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: _currentFormat == 'preview'
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                showCheckmark: false,
              ),
              const Spacer(),

              // Search field in response body
              SizedBox(
                width: 160,
                height: 32,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Search body...',
                    hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 14),
                    suffixIcon: _matchCount > 0
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8, right: 6),
                            child: Text(
                              '$_matchCount',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ],
          ),
        ),

        // Search match banner
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
            child: Row(
              children: [
                Icon(
                  _matchCount > 0 ? Icons.check_circle_outline : Icons.highlight_off,
                  size: 14,
                  color: _matchCount > 0 ? const Color(0xFF10B981) : Colors.orangeAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  _matchCount > 0
                      ? 'Found $_matchCount match${_matchCount == 1 ? '' : 'es'} for "$_searchQuery"'
                      : 'No matches found for "$_searchQuery"',
                  style: TextStyle(
                    fontSize: 11,
                    color: _matchCount > 0 ? const Color(0xFF10B981) : Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ),

        // Body Content Display
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF000000),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: _buildBodyContent(isImage, isHtml),
        ),
      ],
    );
  }

  Widget _buildBodyContent(bool isImage, bool isHtml) {
    if (_currentFormat == 'preview') {
      if (isImage) {
        return _buildImagePreview();
      } else if (isHtml) {
        return _buildHtmlPreview();
      } else {
        return Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.preview_rounded, size: 36, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Preview mode is active. Content-Type: ${_getContentType()}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    }

    if (_currentFormat == 'raw') {
      return SelectableText(
        widget.response.body,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          color: Color(0xFFE0E0E0),
        ),
      );
    }

    // Default 'json' format
    final isJson = _isJsonContentType();
    final formattedText = isJson
        ? _getPrettyJson(widget.response.body)
        : widget.response.body;

    return HighlightView(
      formattedText,
      language: isJson ? 'json' : (isHtml ? 'html' : 'plaintext'),
      theme: atomOneDarkTheme,
      padding: EdgeInsets.zero,
      textStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 12.5,
      ),
    );
  }

  Widget _buildImagePreview() {
    try {
      final bytes = base64Decode(widget.response.body);
      return Center(
        child: Image.memory(
          bytes,
          errorBuilder: (_, __, ___) => const Text(
            'Failed to render image binary data',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      );
    } catch (_) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Image binary payload (${widget.response.sizeFormatted})',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHtmlPreview() {
    // Strip script and head tags for a clean preview of text
    final cleanText = widget.response.body
        .replaceAll(RegExp(r'<script[\s\S]*?</script>'), '')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>'), '')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SelectableText(
        cleanText.isEmpty ? widget.response.body : cleanText,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white70,
          height: 1.4,
        ),
      ),
    );
  }
}
