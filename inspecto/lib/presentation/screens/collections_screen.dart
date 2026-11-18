import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/postman_importer.dart';
import '../../core/utils/openapi_importer.dart';
import '../providers/collection_provider.dart';
import '../providers/request_provider.dart';
import '../providers/workspace_provider.dart';

class CollectionsScreen extends StatefulWidget {
  final VoidCallback? onRequestTapped;
  const CollectionsScreen({super.key, this.onRequestTapped});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<CollectionProvider>().loadCollections();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Import Collection',
            onPressed: () => _showImportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New Collection',
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadCollections(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.collections.isEmpty
                ? const Center(child: Text('No collections yet'))
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.collections.length,
                    itemBuilder: (context, index) {
                      final collection = provider.collections[index];
                      return ExpansionTile(
                        leading: const Icon(Icons.folder, color: Colors.amber),
                        title: Text(collection.name),
                        children: collection.requests.map((request) {
                          return ListTile(
                            title: Text(request.url),
                            subtitle: Text(request.method.name),
                            onTap: () {
                              context.read<WorkspaceProvider>().openRequest(
                                    request,
                                    requestProvider:
                                        context.read<RequestProvider>(),
                                  );
                              widget.onRequestTapped?.call();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Loaded ${request.method.name} ${request.url}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Collection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Collection Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Collection name cannot be empty')),
                );
                return;
              }
              context
                  .read<CollectionProvider>()
                  .createCollection(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    String importType = 'postman'; // 'postman' or 'openapi'
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.file_download_outlined,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Import Collection', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select format:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Postman v2.1 (.json)',
                            style: TextStyle(fontSize: 11)),
                        selected: importType == 'postman',
                        onSelected: (_) =>
                            setDialogState(() => importType = 'postman'),
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('OpenAPI / Swagger (.json)',
                            style: TextStyle(fontSize: 11)),
                        selected: importType == 'openapi',
                        onSelected: (_) =>
                            setDialogState(() => importType = 'openapi'),
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Paste JSON specification:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    maxLines: 10,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12),
                    decoration: InputDecoration(
                      hintText: importType == 'postman'
                          ? '{\n  "info": { "name": "My Collection" },\n  "item": [...] \n}'
                          : '{\n  "openapi": "3.0.0",\n  "info": { "title": "My API" },\n  "paths": {...} \n}',
                      hintStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final content = textController.text.trim();
                if (content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please paste a JSON specification'),
                    ),
                  );
                  return;
                }

                try {
                  final ImportedCollection imported;
                  if (importType == 'postman') {
                    imported = PostmanImporter.parse(content);
                  } else {
                    imported = OpenApiImporter.parse(content);
                  }

                  if (imported.requests.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'No requests found in the imported specification'),
                      ),
                    );
                    return;
                  }

                  final colProvider = context.read<CollectionProvider>();
                  Navigator.pop(dialogContext);

                  await colProvider.importCollection(
                    imported.name,
                    imported.requests,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Imported "${imported.name}" with ${imported.requests.length} requests',
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to import: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.file_download_done_rounded, size: 16),
              label: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }
}
