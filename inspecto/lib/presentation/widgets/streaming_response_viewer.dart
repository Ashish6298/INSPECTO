import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/request_provider.dart';

class StreamingResponseViewer extends StatefulWidget {
  const StreamingResponseViewer({super.key});

  @override
  State<StreamingResponseViewer> createState() =>
      _StreamingResponseViewerState();
}

class _StreamingResponseViewerState extends State<StreamingResponseViewer> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  bool _showRawEvents = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();
    final isStreaming = provider.isStreaming;
    final text = _showRawEvents ? provider.rawStreamLog : provider.streamedText;

    // Trigger auto-scroll on new chunks
    _scrollToBottom();

    // Compute token rate: approx 1 token per 4 chars or 1 token per word
    final wordCount = provider.streamedText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final elapsedSec = provider.streamElapsedMs > 0 ? provider.streamElapsedMs / 1000.0 : 1.0;
    final tokensPerSec = (wordCount / elapsedSec).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isStreaming
                          ? const Color(0xFF10B981)
                          : Colors.grey,
                      boxShadow: isStreaming
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isStreaming ? 'STREAMING ACTIVE' : 'STREAM FINISHED',
                    style: TextStyle(
                      letterSpacing: 1.2,
                      color: isStreaming
                          ? const Color(0xFF10B981)
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (isStreaming)
                    OutlinedButton.icon(
                      onPressed: () => provider.stopStream(),
                      icon: const Icon(Icons.stop_circle_rounded,
                          size: 16, color: Colors.red),
                      label: const Text('STOP STREAM',
                          style: TextStyle(fontSize: 11, color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy Streamed Text',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stream content copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stream Metrics Chips
          Card(
            color: const Color(0xFF050505),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isStreaming
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StreamChip(
                        label: 'Chunks',
                        value: '${provider.streamChunks}',
                        color: const Color(0xFF06B6D4),
                        icon: Icons.layers_rounded,
                      ),
                      _StreamChip(
                        label: 'Speed',
                        value: '$tokensPerSec tok/s',
                        color: Colors.amber[700]!,
                        icon: Icons.speed_rounded,
                      ),
                      _StreamChip(
                        label: 'Elapsed',
                        value: '${provider.streamElapsedMs} ms',
                        color: const Color(0xFF8B5CF6),
                        icon: Icons.timer_rounded,
                      ),
                      _StreamChip(
                        label: 'Size',
                        value: '${(text.length / 1024).toStringAsFixed(1)} KB',
                        color: Colors.blue[700]!,
                        icon: Icons.data_usage_rounded,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Controls: Formatted Text vs Raw SSE
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Formatted Output',
                            style: TextStyle(fontSize: 11)),
                        selected: !_showRawEvents,
                        onSelected: (_) =>
                            setState(() => _showRawEvents = false),
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                        showCheckmark: false,
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Raw SSE Events',
                            style: TextStyle(fontSize: 11)),
                        selected: _showRawEvents,
                        onSelected: (_) =>
                            setState(() => _showRawEvents = true),
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                        showCheckmark: false,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _autoScroll
                              ? Icons.vertical_align_bottom_rounded
                              : Icons.pause_circle_outline_rounded,
                          size: 18,
                          color: _autoScroll
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                        ),
                        tooltip: _autoScroll
                            ? 'Auto-scroll enabled'
                            : 'Auto-scroll paused',
                        onPressed: () =>
                            setState(() => _autoScroll = !_autoScroll),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Live Streaming Text Container
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 180, maxHeight: 420),
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF000000),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: text.isEmpty
                        ? Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Awaiting initial stream chunk from server...',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          )
                        : SelectableText(
                            text,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Color(0xFFE2E8F0),
                              height: 1.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreamChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StreamChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
