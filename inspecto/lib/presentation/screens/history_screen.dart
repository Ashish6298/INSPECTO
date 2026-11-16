import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../providers/request_provider.dart';
import '../../domain/entities/api_request.dart';
import '../../domain/entities/history_item.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onRequestTapped;

  const HistoryScreen({super.key, this.onRequestTapped});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<HistoryProvider>().loadHistory();
      }
    });
  }

  Color _getMethodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.GET:
        return const Color(0xFF10B981);
      case HttpMethod.POST:
        return const Color(0xFF818CF8);
      case HttpMethod.PUT:
        return const Color(0xFFF59E0B);
      case HttpMethod.DELETE:
        return const Color(0xFFEF4444);
      case HttpMethod.PATCH:
        return const Color(0xFF06B6D4);
    }
  }

  Color _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return const Color(0xFF10B981);
    }
    if (statusCode >= 300 && statusCode < 400) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFEF4444);
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
          'This will permanently delete all previously executed request logs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<HistoryProvider>().clearHistory();
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('History'),
            if (historyProvider.history.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${historyProvider.history.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (historyProvider.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClearHistory(context),
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: historyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyProvider.history.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: historyProvider.history.length,
                  itemBuilder: (context, index) {
                    final item = historyProvider.history[index];
                    return _buildHistoryCard(context, item);
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'NO REQUEST HISTORY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Executed API requests will automatically appear here.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryItem item) {
    final methodColor = _getMethodColor(item.request.method);
    final statusColor = _getStatusColor(item.statusCode);
    final formattedTime = DateFormat('MM/dd HH:mm:ss').format(item.timestamp);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) {
        context.read<HistoryProvider>().deleteEntry(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry removed from history'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.read<RequestProvider>().loadRequest(item.request);
            widget.onRequestTapped?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Loaded ${item.request.method.name} ${item.request.url}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Method Badge
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: methodColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: methodColor.withValues(alpha: 0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.request.method.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: methodColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // URL & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.request.url.isEmpty ? '(Empty URL)' : item.request.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            formattedTime,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${item.responseTimeMs} ms',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status Code Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${item.statusCode}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
