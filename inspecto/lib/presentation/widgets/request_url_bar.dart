import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/api_request.dart';
import '../providers/request_provider.dart';
import '../providers/environment_provider.dart';

class RequestUrlBar extends StatelessWidget {
  const RequestUrlBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();
    final envProvider = context.watch<EnvironmentProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (envProvider.activeEnvironment != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFCBA6F7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Color(0xFFCBA6F7).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language,
                          size: 14, color: const Color(0xFFCBA6F7)),
                      const SizedBox(width: 6),
                      Text(
                        envProvider.activeEnvironment!.name,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFCBA6F7),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
            ),
            child: Row(
              children: [
                _MethodDropdown(provider: provider),
                Container(
                    width: 1.5, height: 24, color: const Color(0xFF1A1A1A)),
                Expanded(
                  child: TextField(
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter URL (e.g. {{base_url}}/users)',
                      hintStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                    controller: TextEditingController(text: provider.url)
                      ..selection =
                          TextSelection.collapsed(offset: provider.url.length),
                    onChanged: (value) => provider.setUrl(value),
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

class _MethodDropdown extends StatelessWidget {
  final RequestProvider provider;
  const _MethodDropdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<HttpMethod>(
        value: provider.method,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        items: HttpMethod.values.map((method) {
          return DropdownMenuItem(
            value: method,
            child: Text(
              method.name,
              style: TextStyle(
                color: _getMethodColor(method),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) provider.setMethod(value);
        },
      ),
    );
  }

  Color _getMethodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.GET:
        return const Color(0xFF10B981); // Emerald Green
      case HttpMethod.POST:
        return const Color(0xFFF59E0B); // Amber/Orange
      case HttpMethod.PUT:
        return const Color(0xFF3B82F6); // Blue
      case HttpMethod.DELETE:
        return const Color(0xFFEF4444); // Red
      case HttpMethod.PATCH:
        return const Color(0xFF8B5CF6); // Violet
    }
  }
}
