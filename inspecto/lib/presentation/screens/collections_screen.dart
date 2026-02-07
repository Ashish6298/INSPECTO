import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<CollectionProvider>().loadCollections());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.collections.isEmpty
              ? const Center(child: Text('No collections yet'))
              : ListView.builder(
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
                            // TODO: Load into RequestProvider
                          },
                        );
                      }).toList(),
                    );
                  },
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
}
