import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/request_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/request_url_bar.dart';
import '../widgets/request_tabs.dart';
import '../widgets/response_viewer.dart';
import '../widgets/curl_import_dialog.dart';
import '../widgets/code_snippet_dialog.dart';

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<RequestProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32, width: 32),
            const SizedBox(width: 12),
            const Text(
              'INSPECTO',
              style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.terminal_rounded),
            onPressed: () => CurlImportDialog.show(context),
            tooltip: 'Import cURL',
          ),
          IconButton(
            icon: const Icon(Icons.code_rounded),
            onPressed: () {
              final req = requestProvider.getCurrentRequest();
              CodeSnippetDialog.show(context, req);
            },
            tooltip: 'Generate Code',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () => _showSaveRequestDialog(context),
            tooltip: 'Save Request',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const RequestUrlBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await context.read<RequestProvider>().refresh();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      children: [
                        const RequestTabs(),
                        if (requestProvider.response != null)
                          const ResponseViewer(),
                        if (requestProvider.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        if (requestProvider.response == null &&
                            !requestProvider.isLoading)
                          _EmptyRequestState(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (requestProvider.isRefreshing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Refreshing... Please wait',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: requestProvider.validateUrl()
              ? () {
                  final historyProvider = context.read<HistoryProvider>();
                  requestProvider.sendRequest(
                    onResponseReceived: (req, res) {
                      historyProvider.addEntry(request: req, response: res);
                    },
                  );
                }
              : null,
          elevation: 4,
          icon: const Icon(Icons.bolt_rounded, size: 24),
          label: const Text(
            'SEND REQUEST',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showSaveRequestDialog(BuildContext context) {
    final requestProvider = context.read<RequestProvider>();
    final collectionProvider = context.read<CollectionProvider>();

    if (requestProvider.url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a URL before saving the request'),
        ),
      );
      return;
    }

    // Default request name from URL path or method
    final uri = Uri.tryParse(requestProvider.url);
    final defaultName = uri != null && uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : '${requestProvider.method.name} Request';

    final nameController = TextEditingController(text: defaultName);
    final newCollectionController = TextEditingController();

    String? selectedCollectionId = collectionProvider.collections.isNotEmpty
        ? collectionProvider.collections.first.id
        : null;
    bool isCreatingNewCollection = collectionProvider.collections.isEmpty;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final collections = collectionProvider.collections;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.bookmark_add_rounded, size: 22),
                SizedBox(width: 8),
                Text('Save to Collection',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Name',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Get User Info',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Collection',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 6),
                  if (collections.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: isCreatingNewCollection
                              ? 'new'
                              : selectedCollectionId,
                          isExpanded: true,
                          dropdownColor:
                              Theme.of(context).colorScheme.surface,
                          items: [
                            ...collections.map((col) => DropdownMenuItem(
                                  value: col.id,
                                  child: Text(col.name,
                                      overflow: TextOverflow.ellipsis),
                                )),
                            const DropdownMenuItem(
                              value: 'new',
                              child: Text('+ Create New Collection',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == 'new') {
                                isCreatingNewCollection = true;
                              } else {
                                isCreatingNewCollection = false;
                                selectedCollectionId = val;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isCreatingNewCollection)
                    TextField(
                      controller: newCollectionController,
                      decoration: const InputDecoration(
                        hintText: 'New Collection Name',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final reqName = nameController.text.trim().isEmpty
                      ? defaultName
                      : nameController.text.trim();
                  String? targetCollectionId = selectedCollectionId;

                  if (isCreatingNewCollection) {
                    final newColName = newCollectionController.text.trim();
                    if (newColName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a collection name')),
                      );
                      return;
                    }
                    await collectionProvider.createCollection(newColName);
                    final matched = collectionProvider.collections.firstWhere(
                      (c) => c.name == newColName,
                      orElse: () => collectionProvider.collections.last,
                    );
                    targetCollectionId = matched.id;
                  }

                  if (targetCollectionId == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No collection selected')),
                      );
                    }
                    return;
                  }

                  final requestToSave = requestProvider.getCurrentRequest();
                  await collectionProvider.saveToCollection(
                      targetCollectionId, requestToSave);

                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Saved "$reqName" to collection')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyRequestState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          Text(
            'NO ACTIVE REQUEST',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              letterSpacing: 2,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter a URL above to start testing your APIs.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
