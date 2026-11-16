import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/request_provider.dart';
import 'response_body_view.dart';
import 'response_cookies_view.dart';
import 'response_headers_view.dart';

class ResponseViewer extends StatefulWidget {
  const ResponseViewer({super.key});

  @override
  State<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends State<ResponseViewer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        final response = provider.response;
        if (response == null) return const SizedBox.shrink();

        final isSuccess =
            response.statusCode >= 200 && response.statusCode < 300;
        final cookies = ParsedCookie.parseHeaders(response.headers);
        final headerCount = response.headers.length;
        final cookieCount = cookies.length;

        String? contentType;
        for (final entry in response.headers.entries) {
          if (entry.key.toLowerCase() == 'content-type') {
            contentType = entry.value.split(';').first.trim();
            break;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title & quick action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RESPONSE',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 1.2,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy Response Body',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: response.body));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Response copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Main Response Card
              Card(
                color: const Color(0xFF050505),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metrics Chips
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            label: 'Status',
                            value: '${response.statusCode}',
                            color: isSuccess
                                ? const Color(0xFF10B981)
                                : Colors.red,
                            icon: isSuccess
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                          ),
                          _InfoChip(
                            label: 'Time',
                            value: '${response.responseTimeMs} ms',
                            color: Colors.amber[700]!,
                            icon: Icons.speed_rounded,
                          ),
                          _InfoChip(
                            label: 'Size',
                            value: response.sizeFormatted,
                            color: Colors.blue[700]!,
                            icon: Icons.data_usage_rounded,
                          ),
                          if (contentType != null && contentType.isNotEmpty)
                            _InfoChip(
                              label: 'Type',
                              value: contentType,
                              color: const Color(0xFFCBA6F7),
                              icon: Icons.category_outlined,
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Sub-tabs
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: [
                        const Tab(text: 'Body'),
                        Tab(text: 'Headers ($headerCount)'),
                        Tab(text: 'Cookies ($cookieCount)'),
                        const Tab(text: 'Raw'),
                      ],
                    ),
                    const Divider(height: 1),

                    // Active Tab View Content
                    switch (_tabController.index) {
                      0 => ResponseBodyView(
                          response: response,
                          initialFormat: 'json',
                        ),
                      1 => ResponseHeadersView(
                          headers: response.headers,
                        ),
                      2 => ResponseCookiesView(
                          headers: response.headers,
                        ),
                      3 => ResponseBodyView(
                          response: response,
                          initialFormat: 'raw',
                        ),
                      _ => const SizedBox.shrink(),
                    },
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
