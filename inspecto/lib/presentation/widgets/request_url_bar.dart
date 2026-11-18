import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/api_request.dart';
import '../../domain/entities/execution_engine.dart';
import '../providers/request_provider.dart';
import '../providers/environment_provider.dart';

class RequestUrlBar extends StatelessWidget {
  final FocusNode? focusNode;
  const RequestUrlBar({super.key, this.focusNode});

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (envProvider.activeEnvironment != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBA6F7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFCBA6F7).withValues(alpha: 0.3)),
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
                )
              else
                const SizedBox.shrink(),

              // Execution Engine Switcher Chip (Direct vs Proxy)
              _EngineToggleChip(
                engine: provider.executionEngine,
                onChanged: (newEngine) =>
                    provider.setExecutionEngine(newEngine),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: provider.url.isNotEmpty && !provider.validateUrl()
                    ? Colors.red.withValues(alpha: 0.5)
                    : Theme.of(context).dividerColor,
                width: Theme.of(context).brightness == Brightness.dark ? 1.5 : 1.0,
              ),
              boxShadow: Theme.of(context).brightness == Brightness.light
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                _MethodDropdown(provider: provider),
                Container(
                    width: 1.5,
                    height: 24,
                    color: Theme.of(context).dividerColor),
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
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
                              .withValues(alpha: 0.4)),
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

class _EngineToggleChip extends StatelessWidget {
  final ExecutionEngine engine;
  final ValueChanged<ExecutionEngine> onChanged;

  const _EngineToggleChip({
    required this.engine,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDirect = engine == ExecutionEngine.direct;
    final color = isDirect ? const Color(0xFF06B6D4) : const Color(0xFF8B5CF6);
    final label = isDirect ? 'Direct (Local)' : 'Proxy (Server)';
    final icon = isDirect ? Icons.bolt_rounded : Icons.dns_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          onChanged(
            isDirect ? ExecutionEngine.proxy : ExecutionEngine.direct,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.swap_horiz_rounded,
                  size: 12, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
