import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/variable_extractor.dart';
import '../providers/request_provider.dart';
import '../providers/environment_provider.dart';

class PostRequestTab extends StatefulWidget {
  const PostRequestTab({super.key});

  @override
  State<PostRequestTab> createState() => _PostRequestTabState();
}

class _PostRequestTabState extends State<PostRequestTab> {
  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<RequestProvider>();
    final envProvider = context.watch<EnvironmentProvider>();
    final extractors = requestProvider.extractors;
    final activeEnv = envProvider.activeEnvironment;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: activeEnv != null
                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                  : Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeEnv != null
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  activeEnv != null
                      ? Icons.link_rounded
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: activeEnv != null
                      ? const Color(0xFF10B981)
                      : Colors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeEnv != null
                        ? 'Chaining to active environment: "${activeEnv.name}"'
                        : 'No active environment selected. Variables cannot be saved.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: activeEnv != null
                          ? const Color(0xFF10B981)
                          : Colors.amber,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'POST-RESPONSE EXTRACTORS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  requestProvider.addExtractor(
                    VariableExtractor(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      source: ExtractorSource.responseBody,
                      pathOrKey: '',
                      targetVariable: '',
                      enabled: true,
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Add Rule', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (extractors.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 36,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No variable extractors configured',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Automatically capture auth tokens, session IDs, or IDs from response bodies (JSONPath) or headers and write them straight into environment variables.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      requestProvider.addExtractor(
                        VariableExtractor(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          source: ExtractorSource.responseBody,
                          pathOrKey: 'token',
                          targetVariable: 'authToken',
                          enabled: true,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('Add Example (token -> authToken)',
                        style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: const Size(0, 34),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: extractors.length,
              itemBuilder: (context, index) {
                return _ExtractorCard(
                  key: ValueKey(extractors[index].id),
                  extractor: extractors[index],
                  index: index,
                  onUpdate: (updated) =>
                      requestProvider.updateExtractor(index, updated),
                  onDelete: () => requestProvider.removeExtractor(index),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ExtractorCard extends StatefulWidget {
  final VariableExtractor extractor;
  final int index;
  final ValueChanged<VariableExtractor> onUpdate;
  final VoidCallback onDelete;

  const _ExtractorCard({
    super.key,
    required this.extractor,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_ExtractorCard> createState() => _ExtractorCardState();
}

class _ExtractorCardState extends State<_ExtractorCard> {
  late TextEditingController _pathController;
  late TextEditingController _variableController;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.extractor.pathOrKey);
    _variableController =
        TextEditingController(text: widget.extractor.targetVariable);
  }

  @override
  void didUpdateWidget(covariant _ExtractorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extractor.pathOrKey != widget.extractor.pathOrKey) {
      _pathController.text = widget.extractor.pathOrKey;
    }
    if (oldWidget.extractor.targetVariable !=
        widget.extractor.targetVariable) {
      _variableController.text = widget.extractor.targetVariable;
    }
  }

  @override
  void dispose() {
    _pathController.dispose();
    _variableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extractor = widget.extractor;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: extractor.enabled
              ? Theme.of(context).dividerColor
              : Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                // Source dropdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ExtractorSource>(
                      value: extractor.source,
                      isDense: true,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ExtractorSource.responseBody,
                          child: Text('Body (JSONPath)'),
                        ),
                        DropdownMenuItem(
                          value: ExtractorSource.responseHeader,
                          child: Text('Header'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          widget.onUpdate(extractor.copyWith(source: val));
                        }
                      },
                    ),
                  ),
                ),
                const Spacer(),

                // Enable/Disable Switch
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: extractor.enabled,
                    onChanged: (enabled) {
                      widget.onUpdate(extractor.copyWith(enabled: enabled));
                    },
                  ),
                ),

                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  color: Colors.red.withValues(alpha: 0.7),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete extractor',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Inputs Row: Path -> Target
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _pathController,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      labelText: extractor.source == ExtractorSource.responseBody
                          ? 'JSON Path (e.g. data.token)'
                          : 'Header Key (e.g. Authorization)',
                      labelStyle: const TextStyle(fontSize: 10),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onChanged: (val) {
                      widget.onUpdate(extractor.copyWith(pathOrKey: val));
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Colors.grey),
                ),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _variableController,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      labelText: 'Target Variable (e.g. authToken)',
                      labelStyle: const TextStyle(fontSize: 10),
                      prefixText: '{{ ',
                      prefixStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFCBA6F7),
                          fontWeight: FontWeight.bold),
                      suffixText: ' }}',
                      suffixStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFCBA6F7),
                          fontWeight: FontWeight.bold),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onChanged: (val) {
                      widget.onUpdate(extractor.copyWith(targetVariable: val));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
