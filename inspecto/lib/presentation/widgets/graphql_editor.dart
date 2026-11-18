import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/graphql_introspection.dart';
import '../../domain/entities/api_request.dart';
import '../../domain/entities/api_response.dart';
import '../../data/repositories/api_repository_impl.dart';
import '../providers/request_provider.dart';
import '../providers/environment_provider.dart';

class GraphQLEditor extends StatefulWidget {
  const GraphQLEditor({super.key});

  @override
  State<GraphQLEditor> createState() => _GraphQLEditorState();
}

class _GraphQLEditorState extends State<GraphQLEditor> {
  late TextEditingController _queryController;
  late TextEditingController _variablesController;
  bool _isIntrospecting = false;
  GraphQLSchemaDoc? _schemaDoc;

  @override
  void initState() {
    super.initState();
    final provider = context.read<RequestProvider>();
    final parsed =
        GraphQLIntrospection.extractQueryAndVariables(provider.body);

    _queryController = TextEditingController(text: parsed.query);
    _variablesController = TextEditingController(text: parsed.variables);

    _queryController.addListener(_syncToProvider);
    _variablesController.addListener(_syncToProvider);
  }

  @override
  void dispose() {
    _queryController.removeListener(_syncToProvider);
    _variablesController.removeListener(_syncToProvider);
    _queryController.dispose();
    _variablesController.dispose();
    super.dispose();
  }

  void _syncToProvider() {
    final provider = context.read<RequestProvider>();
    final payload = GraphQLIntrospection.buildPayload(
      _queryController.text,
      _variablesController.text,
    );
    if (provider.body != payload) {
      provider.setBody(payload);
    }
  }

  void _formatCode() {
    // 1. Format GraphQL Query
    final formattedQuery =
        GraphQLIntrospection.formatGraphQL(_queryController.text);
    if (formattedQuery.isNotEmpty) {
      _queryController.text = formattedQuery;
    }

    // 2. Format Variables JSON
    final rawVars = _variablesController.text.trim();
    if (rawVars.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawVars);
        _variablesController.text =
            const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        // Leave as is if invalid JSON
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GraphQL Query & Variables Formatted'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _fetchSchema() async {
    final requestProvider = context.read<RequestProvider>();
    final envProvider = context.read<EnvironmentProvider>();

    if (requestProvider.url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a target GraphQL URL first'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isIntrospecting = true;
    });

    try {
      final req = ApiRequest(
        id: 'introspection_${DateTime.now().millisecondsSinceEpoch}',
        method: HttpMethod.POST,
        url: requestProvider.url,
        headers: {
          ...requestProvider.headers,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        params: requestProvider.params,
        body: jsonEncode({
          'query': GraphQLIntrospection.introspectionQuery,
        }),
        bodyType: 'graphql',
        bodySubType: 'json',
        authType: requestProvider.authType,
        authDetails: requestProvider.authDetails,
      );

      final ApiResponse response =
          await (requestProvider.apiRepository as ApiRepositoryImpl)
              .executeWithEnvironment(
        req,
        requestProvider.environmentId ?? envProvider.activeEnvironment?.id,
        engine: requestProvider.executionEngine,
        environmentVariables: envProvider.activeEnvironment?.variables,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final doc = GraphQLIntrospection.parseSchema(decoded);
        if (doc.isNotEmpty) {
          setState(() {
            _schemaDoc = doc;
            _isIntrospecting = false;
          });
          if (mounted) {
            _openSchemaExplorer(doc);
          }
          return;
        } else {
          throw Exception(
              'Failed to parse schema. No types or queries returned.');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isIntrospecting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Introspection failed: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _openSchemaExplorer(GraphQLSchemaDoc schema) {
    showDialog(
      context: context,
      builder: (ctx) => _SchemaExplorerDialog(
        schema: schema,
        onInsertSnippet: (snippet) {
          setState(() {
            _queryController.text = snippet;
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // GraphQL Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                'GRAPHQL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              // Format Button
              OutlinedButton.icon(
                onPressed: _formatCode,
                icon: const Icon(Icons.auto_fix_high, size: 14),
                label: const Text('Format', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const SizedBox(width: 8),
              // Schema Introspection Button
              ElevatedButton.icon(
                onPressed: _isIntrospecting ? null : _fetchSchema,
                icon: _isIntrospecting
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.menu_book, size: 14),
                label: Text(
                  _schemaDoc != null ? 'Docs / Schema' : 'Fetch Schema',
                  style: const TextStyle(fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ),

        // Split Editor Layout
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Top: GraphQL Query Editor
                    Expanded(
                      flex: 6,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 8,
                            right: 12,
                            child: Text(
                              'QUERY / MUTATION',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                            child: TextField(
                              controller: _queryController,
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                              cursorColor: theme.colorScheme.primary,
                              decoration: InputDecoration(
                                hintText:
                                    'query GetItems {\n  items {\n    id\n    name\n  }\n}',
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.25),
                                  fontFamily: 'monospace',
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider between Query and Variables
                    Container(
                      height: 1,
                      color: theme.dividerColor,
                    ),

                    // Bottom: Variables Editor
                    Expanded(
                      flex: 4,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 8,
                            right: 12,
                            child: Text(
                              'QUERY VARIABLES (JSON)',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                            child: TextField(
                              controller: _variablesController,
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                              cursorColor: theme.colorScheme.primary,
                              decoration: InputDecoration(
                                hintText: '{\n  "limit": 10\n}',
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.25),
                                  fontFamily: 'monospace',
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Modal dialog displaying GraphQL Schema Documentation Explorer
class _SchemaExplorerDialog extends StatefulWidget {
  final GraphQLSchemaDoc schema;
  final ValueChanged<String> onInsertSnippet;

  const _SchemaExplorerDialog({
    required this.schema,
    required this.onInsertSnippet,
  });

  @override
  State<_SchemaExplorerDialog> createState() => _SchemaExplorerDialogState();
}

class _SchemaExplorerDialogState extends State<_SchemaExplorerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _filter = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queries = widget.schema.queries
        .where((q) =>
            q.name.toLowerCase().contains(_filter) ||
            q.returnType.toLowerCase().contains(_filter) ||
            (q.description?.toLowerCase().contains(_filter) ?? false))
        .toList();

    final mutations = widget.schema.mutations
        .where((m) =>
            m.name.toLowerCase().contains(_filter) ||
            m.returnType.toLowerCase().contains(_filter) ||
            (m.description?.toLowerCase().contains(_filter) ?? false))
        .toList();

    final types = widget.schema.types
        .where((t) =>
            t.name.toLowerCase().contains(_filter) ||
            t.kind.toLowerCase().contains(_filter) ||
            (t.description?.toLowerCase().contains(_filter) ?? false))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.colorScheme.surface,
      child: Container(
        width: 720,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.menu_book, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'GraphQL Schema Explorer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Filter queries, mutations, or types...',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              indicatorColor: theme.colorScheme.primary,
              tabs: [
                Tab(text: 'Queries (${queries.length})'),
                Tab(text: 'Mutations (${mutations.length})'),
                Tab(text: 'Types (${types.length})'),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFieldsList(queries, isMutation: false),
                  _buildFieldsList(mutations, isMutation: true),
                  _buildTypesList(types),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsList(List<GraphQLFieldDoc> fields,
      {required bool isMutation}) {
    if (fields.isEmpty) {
      return Center(
        child: Text(
          isMutation ? 'No mutations found' : 'No queries found',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: fields.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, index) {
        final field = fields[index];
        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          title: Row(
            children: [
              Text(
                field.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ': ${field.returnType}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (field.isDeprecated) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DEPRECATED',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (field.description != null && field.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    field.description!,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              if (field.args.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 6,
                    children: field.args.map((arg) {
                      return Chip(
                        label: Text(
                          arg.toString(),
                          style: const TextStyle(
                              fontSize: 10, fontFamily: 'monospace'),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
          trailing: IconButton(
            tooltip: 'Insert boilerplate into editor',
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: () {
              final snippet = field.generateSnippet(isMutation: isMutation);
              widget.onInsertSnippet(snippet);
            },
          ),
        );
      },
    );
  }

  Widget _buildTypesList(List<GraphQLTypeDoc> types) {
    if (types.isEmpty) {
      return const Center(
        child: Text('No types found', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      itemCount: types.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, index) {
        final type = types[index];
        return ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type.kind,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                type.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ],
          ),
          subtitle: type.description != null && type.description!.isNotEmpty
              ? Text(
                  type.description!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                )
              : null,
          children: type.fields.map((field) {
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 32, right: 16),
              title: Text(
                '${field.name}: ${field.returnType}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              subtitle: field.description != null
                  ? Text(field.description!,
                      style: const TextStyle(fontSize: 10, color: Colors.grey))
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
}
