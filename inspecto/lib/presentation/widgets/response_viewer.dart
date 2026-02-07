import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../providers/request_provider.dart';

class ResponseViewer extends StatelessWidget {
  const ResponseViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        final response = provider.response;
        if (response == null) return const SizedBox.shrink();

        final isSuccess =
            response.statusCode >= 200 && response.statusCode < 300;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RESPONSE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.2,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFF050505),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF000000),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: HighlightView(
                        response.body,
                        language: 'json',
                        theme: atomOneDarkTheme,
                        padding: const EdgeInsets.all(12),
                        textStyle: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
