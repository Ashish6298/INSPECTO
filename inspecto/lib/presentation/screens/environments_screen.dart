import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import '../widgets/key_value_list.dart';

class EnvironmentsScreen extends StatefulWidget {
  const EnvironmentsScreen({super.key});

  @override
  State<EnvironmentsScreen> createState() => _EnvironmentsScreenState();
}

class _EnvironmentsScreenState extends State<EnvironmentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<EnvironmentProvider>().loadEnvironments());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EnvironmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Environments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: provider.environments.isEmpty
          ? const Center(child: Text('No environments yet'))
          : ListView.builder(
              itemCount: provider.environments.length,
              itemBuilder: (context, index) {
                final env = provider.environments[index];
                return ListTile(
                  leading: const Icon(Icons.language, color: Colors.blue),
                  title: Text(env.name),
                  subtitle: Text('${env.variables.length} variables'),
                  trailing: Switch(
                    value: provider.activeEnvironment?.id == env.id,
                    onChanged: (value) {
                      provider.setActiveEnvironment(value ? env : null);
                    },
                  ),
                  onTap: () => _showVariablesDialog(context, env),
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
        title: const Text('New Environment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Environment Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context
                  .read<EnvironmentProvider>()
                  .addEnvironment(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showVariablesDialog(BuildContext context, dynamic env) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Variables for ${env.name}',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: KeyValueList(
                title: 'Variables',
                data: env.variables,
                onChanged: (newData) {
                  // This is simplified, in a real app you'd want a separate provider method
                  final provider = context.read<EnvironmentProvider>();
                  for (var key in newData.keys) {
                    provider.updateVariable(env.id, key, newData[key]!);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
