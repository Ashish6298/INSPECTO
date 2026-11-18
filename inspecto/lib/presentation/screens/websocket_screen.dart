import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/websocket_data_source.dart';
import '../providers/websocket_provider.dart';

class WebSocketScreen extends StatefulWidget {
  const WebSocketScreen({super.key});

  @override
  State<WebSocketScreen> createState() => _WebSocketScreenState();
}

class _WebSocketScreenState extends State<WebSocketScreen> {
  late TextEditingController _urlController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<WebSocketProvider>();
    _urlController = TextEditingController(text: provider.url);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WebSocketProvider>();
    final isConnected = provider.status == WebSocketStatus.connected;
    final isConnecting = provider.status == WebSocketStatus.connecting;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.cable_rounded, size: 22),
            const SizedBox(width: 8),
            const Text(
              'WEBSOCKET CLIENT',
              style: TextStyle(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          if (provider.frames.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear Timeline',
              onPressed: () => provider.clearFrames(),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Connection Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Status dot
                      _StatusBadge(status: provider.status),
                      const SizedBox(width: 8),

                      // URL Input
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          enabled: !isConnected && !isConnecting,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'wss://echo.websocket.org',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) => provider.setUrl(val),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Connect / Disconnect Action Button
                      if (isConnected)
                        ElevatedButton.icon(
                          onPressed: () => provider.disconnect(),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('DISCONNECT',
                              style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                        )
                      else if (isConnecting)
                        ElevatedButton.icon(
                          onPressed: null,
                          icon: const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          label: const Text('CONNECTING...',
                              style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => provider.connect(
                            customUrl: _urlController.text,
                          ),
                          icon: const Icon(Icons.flash_on_rounded, size: 16),
                          label: const Text('CONNECT',
                              style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                    ],
                  ),

                  // Error notification if connection failed
                  if (provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.red, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                provider.errorMessage!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Message Composer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MESSAGE COMPOSER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          _PresetChip(
                            label: 'JSON Ping',
                            onTap: () {
                              _messageController.text =
                                  '{"type": "ping", "timestamp": ${DateTime.now().millisecondsSinceEpoch}}';
                            },
                          ),
                          _PresetChip(
                            label: 'Echo Test',
                            onTap: () {
                              _messageController.text =
                                  'Hello from Inspecto WebSocket Client!';
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: 3,
                          minLines: 1,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Type message or JSON payload to send over socket...',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                              fontSize: 11.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(10),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: isConnected
                            ? () {
                                final text = _messageController.text;
                                if (text.trim().isNotEmpty) {
                                  provider.sendMessage(text);
                                  _messageController.clear();
                                }
                              }
                            : null,
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('SEND'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          minimumSize: const Size(0, 42),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Filter Bar & Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('All (${provider.frames.length})',
                      style: const TextStyle(fontSize: 11)),
                  selected: provider.filter == 'all',
                  onSelected: (_) => provider.setFilter('all'),
                  selectedColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  showCheckmark: false,
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: Text('Inbound (${provider.inboundCount})',
                      style: const TextStyle(fontSize: 11)),
                  selected: provider.filter == 'inbound',
                  onSelected: (_) => provider.setFilter('inbound'),
                  selectedColor: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                  showCheckmark: false,
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: Text('Outbound (${provider.outboundCount})',
                      style: const TextStyle(fontSize: 11)),
                  selected: provider.filter == 'outbound',
                  onSelected: (_) => provider.setFilter('outbound'),
                  selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                  showCheckmark: false,
                ),
                const Spacer(),
                SizedBox(
                  width: 140,
                  height: 32,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Filter frames...',
                      hintStyle:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, size: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      isDense: true,
                    ),
                    onChanged: (val) => provider.setSearchQuery(val),
                  ),
                ),
              ],
            ),
          ),

          // 4. Live Timeline Feed
          Expanded(
            child: provider.filteredFrames.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sync_alt_rounded,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isConnected
                              ? 'Connected to socket. Send a message to inspect frames.'
                              : 'Connect to an endpoint to begin monitoring WebSocket frames.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: provider.filteredFrames.length,
                    itemBuilder: (context, index) {
                      final frame = provider.filteredFrames[index];
                      return _WebSocketFrameCard(frame: frame);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final WebSocketStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case WebSocketStatus.connected:
        color = const Color(0xFF10B981);
        label = 'Connected';
        break;
      case WebSocketStatus.connecting:
        color = const Color(0xFFF59E0B);
        label = 'Connecting';
        break;
      case WebSocketStatus.error:
        color = Colors.red;
        label = 'Error';
        break;
      case WebSocketStatus.disconnected:
        color = Colors.grey;
        label = 'Disconnected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
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

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _WebSocketFrameCard extends StatelessWidget {
  final WebSocketFrame frame;
  const _WebSocketFrameCard({required this.frame});

  @override
  Widget build(BuildContext context) {
    final isInbound = frame.isInbound;
    final color =
        isInbound ? const Color(0xFF06B6D4) : const Color(0xFF10B981);
    final icon = isInbound
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final label = isInbound ? 'RECEIVED' : 'SENT';
    final timeStr = DateFormat('HH:mm:ss.SSS').format(frame.timestamp);

    return Align(
      alignment: isInbound ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${frame.byteLength} B',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 13),
                      tooltip: 'Copy Payload',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: frame.payload));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payload copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Payload Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                frame.payload,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFFE2E8F0),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
