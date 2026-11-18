import 'dart:convert';

/// Representation of a GraphQL field argument
class GraphQLArgDoc {
  final String name;
  final String? description;
  final String type;
  final String? defaultValue;

  const GraphQLArgDoc({
    required this.name,
    this.description,
    required this.type,
    this.defaultValue,
  });

  @override
  String toString() {
    if (defaultValue != null && defaultValue!.isNotEmpty) {
      return '$name: $type = $defaultValue';
    }
    return '$name: $type';
  }
}

/// Representation of a field in a GraphQL type or root query/mutation
class GraphQLFieldDoc {
  final String name;
  final String? description;
  final String returnType;
  final List<GraphQLArgDoc> args;
  final bool isDeprecated;
  final String? deprecationReason;

  const GraphQLFieldDoc({
    required this.name,
    this.description,
    required this.returnType,
    this.args = const [],
    this.isDeprecated = false,
    this.deprecationReason,
  });

  /// Readable signature, e.g.: `user(id: ID!): User`
  String get signature {
    if (args.isEmpty) {
      return '$name: $returnType';
    }
    final argsStr = args.map((a) => a.toString()).join(', ');
    return '$name($argsStr): $returnType';
  }

  /// Generates a starter query or mutation snippet
  String generateSnippet({bool isMutation = false}) {
    final buffer = StringBuffer();
    final op = isMutation ? 'mutation' : 'query';
    final capitalized = name.isNotEmpty
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : 'Operation';

    if (args.isNotEmpty) {
      final varDefs = args.map((a) => '\$${a.name}: ${a.type}').join(', ');
      final varPass = args.map((a) => '${a.name}: \$${a.name}').join(', ');
      buffer.writeln('$op $capitalized($varDefs) {');
      buffer.writeln('  $name($varPass) {');
      buffer.writeln('    # Add fields here');
      buffer.writeln('  }');
      buffer.writeln('}');
    } else {
      buffer.writeln('$op $capitalized {');
      buffer.writeln('  $name {');
      buffer.writeln('    # Add fields here');
      buffer.writeln('  }');
      buffer.writeln('}');
    }
    return buffer.toString().trim();
  }
}

/// Representation of a GraphQL Type (Object, Interface, Enum, Scalar, Input)
class GraphQLTypeDoc {
  final String kind;
  final String name;
  final String? description;
  final List<GraphQLFieldDoc> fields;

  const GraphQLTypeDoc({
    required this.kind,
    required this.name,
    this.description,
    this.fields = const [],
  });
}

/// Introspected schema representation containing queries, mutations, and types
class GraphQLSchemaDoc {
  final String queryTypeName;
  final String? mutationTypeName;
  final String? subscriptionTypeName;
  final List<GraphQLFieldDoc> queries;
  final List<GraphQLFieldDoc> mutations;
  final List<GraphQLTypeDoc> types;

  const GraphQLSchemaDoc({
    this.queryTypeName = 'Query',
    this.mutationTypeName,
    this.subscriptionTypeName,
    this.queries = const [],
    this.mutations = const [],
    this.types = const [],
  });

  factory GraphQLSchemaDoc.empty() => const GraphQLSchemaDoc();

  bool get isEmpty => queries.isEmpty && mutations.isEmpty && types.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Utility for GraphQL payload generation, parsing, query formatting,
/// and schema introspection.
class GraphQLIntrospection {
  /// Standard GraphQL Introspection Query
  static const String introspectionQuery = r'''
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      kind
      name
      description
      fields(includeDeprecated: true) {
        name
        description
        args {
          name
          description
          type {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                }
              }
            }
          }
          defaultValue
        }
        type {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
        isDeprecated
        deprecationReason
      }
    }
  }
}
''';

  /// Converts a nested type map from introspection into a human-readable GraphQL type
  /// e.g. `[User!]!`
  static String renderType(Map<String, dynamic>? typeMap) {
    if (typeMap == null) return 'Unknown';
    final kind = typeMap['kind']?.toString() ?? '';
    final name = typeMap['name']?.toString();
    final ofType = typeMap['ofType'] as Map<String, dynamic>?;

    if (kind == 'NON_NULL') {
      return '${renderType(ofType)}!';
    } else if (kind == 'LIST') {
      return '[${renderType(ofType)}]';
    } else {
      return name ?? 'Unknown';
    }
  }

  /// Parses standard introspection response into a [GraphQLSchemaDoc]
  static GraphQLSchemaDoc parseSchema(dynamic jsonInput) {
    if (jsonInput == null) return GraphQLSchemaDoc.empty();

    Map<String, dynamic>? schemaMap;
    if (jsonInput is Map<String, dynamic>) {
      if (jsonInput.containsKey('data') &&
          jsonInput['data'] is Map<String, dynamic>) {
        final data = jsonInput['data'] as Map<String, dynamic>;
        schemaMap = data['__schema'] as Map<String, dynamic>?;
      } else if (jsonInput.containsKey('__schema') &&
          jsonInput['__schema'] is Map<String, dynamic>) {
        schemaMap = jsonInput['__schema'] as Map<String, dynamic>;
      } else {
        schemaMap = jsonInput;
      }
    }

    if (schemaMap == null) return GraphQLSchemaDoc.empty();

    final queryTypeName =
        schemaMap['queryType']?['name']?.toString() ?? 'Query';
    final mutationTypeName = schemaMap['mutationType']?['name']?.toString();
    final subscriptionTypeName =
        schemaMap['subscriptionType']?['name']?.toString();

    final rawTypes = (schemaMap['types'] as List<dynamic>?) ?? [];
    final List<GraphQLTypeDoc> allTypes = [];
    final List<GraphQLFieldDoc> queries = [];
    final List<GraphQLFieldDoc> mutations = [];

    for (final raw in rawTypes) {
      if (raw is! Map<String, dynamic>) continue;
      final typeName = raw['name']?.toString() ?? '';
      // Exclude internal introspection types like __Schema, __Type, etc.
      if (typeName.startsWith('__')) continue;

      final typeDoc = _parseTypeDoc(raw);
      allTypes.add(typeDoc);

      if (typeName == queryTypeName) {
        queries.addAll(typeDoc.fields);
      } else if (typeName == mutationTypeName) {
        mutations.addAll(typeDoc.fields);
      }
    }

    return GraphQLSchemaDoc(
      queryTypeName: queryTypeName,
      mutationTypeName: mutationTypeName,
      subscriptionTypeName: subscriptionTypeName,
      queries: queries,
      mutations: mutations,
      types: allTypes
          .where((t) => t.name != queryTypeName && t.name != mutationTypeName)
          .toList(),
    );
  }

  static GraphQLTypeDoc _parseTypeDoc(Map<String, dynamic> raw) {
    final kind = raw['kind']?.toString() ?? 'OBJECT';
    final name = raw['name']?.toString() ?? 'Unnamed';
    final description = raw['description']?.toString();

    final rawFields = (raw['fields'] as List<dynamic>?) ?? [];
    final List<GraphQLFieldDoc> fields = [];

    for (final rf in rawFields) {
      if (rf is! Map<String, dynamic>) continue;
      final fName = rf['name']?.toString() ?? '';
      final fDesc = rf['description']?.toString();
      final returnType = renderType(rf['type'] as Map<String, dynamic>?);
      final isDeprecated = rf['isDeprecated'] == true;
      final deprecationReason = rf['deprecationReason']?.toString();

      final rawArgs = (rf['args'] as List<dynamic>?) ?? [];
      final List<GraphQLArgDoc> args = [];
      for (final ra in rawArgs) {
        if (ra is! Map<String, dynamic>) continue;
        args.add(GraphQLArgDoc(
          name: ra['name']?.toString() ?? '',
          description: ra['description']?.toString(),
          type: renderType(ra['type'] as Map<String, dynamic>?),
          defaultValue: ra['defaultValue']?.toString(),
        ));
      }

      fields.add(GraphQLFieldDoc(
        name: fName,
        description: fDesc,
        returnType: returnType,
        args: args,
        isDeprecated: isDeprecated,
        deprecationReason: deprecationReason,
      ));
    }

    return GraphQLTypeDoc(
      kind: kind,
      name: name,
      description: description,
      fields: fields,
    );
  }

  /// Builds standard GraphQL HTTP POST JSON payload:
  /// `{"query": "...", "variables": {...}}`
  static String buildPayload(String query, String variablesJson) {
    dynamic parsedVariables = {};
    final trimmedVars = variablesJson.trim();
    if (trimmedVars.isNotEmpty) {
      try {
        final decoded = jsonDecode(trimmedVars);
        if (decoded is Map || decoded is List) {
          parsedVariables = decoded;
        }
      } catch (_) {
        parsedVariables = {};
      }
    }

    return jsonEncode({
      'query': query,
      'variables': parsedVariables,
    });
  }

  /// Extracts query string and formatted variables JSON from request body.
  /// Handles both wrapped JSON payloads and raw GraphQL strings.
  static ({String query, String variables}) extractQueryAndVariables(
      String? rawBody) {
    if (rawBody == null || rawBody.trim().isEmpty) {
      return (query: '', variables: '{}');
    }

    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        final query = decoded['query']?.toString() ?? '';
        final vars = decoded['variables'];
        String varsStr = '{}';
        if (vars != null) {
          if (vars is Map || vars is List) {
            varsStr = const JsonEncoder.withIndent('  ').convert(vars);
          } else {
            varsStr = vars.toString();
          }
        }
        return (query: query, variables: varsStr);
      }
    } catch (_) {
      // Not JSON, assume it's directly the query
    }

    return (query: rawBody, variables: '{}');
  }

  /// Formats and auto-indents a GraphQL query string.
  static String formatGraphQL(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return '';

    // Tokenize GraphQL characters while preserving quoted strings and comments
    final List<String> tokens = [];
    final StringBuffer currentToken = StringBuffer();
    bool inString = false;
    bool inComment = false;

    for (int i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];

      if (inComment) {
        if (char == '\n' || char == '\r') {
          inComment = false;
          tokens.add(currentToken.toString().trim());
          currentToken.clear();
        } else {
          currentToken.write(char);
        }
        continue;
      }

      if (char == '#') {
        if (currentToken.toString().trim().isNotEmpty) {
          tokens.add(currentToken.toString().trim());
          currentToken.clear();
        }
        inComment = true;
        currentToken.write(char);
        continue;
      }

      if (char == '"') {
        currentToken.write(char);
        inString = !inString;
        if (!inString) {
          tokens.add(currentToken.toString());
          currentToken.clear();
        }
        continue;
      }

      if (inString) {
        currentToken.write(char);
        continue;
      }

      if (char == '{' ||
          char == '}' ||
          char == '(' ||
          char == ')' ||
          char == ':' ||
          char == ',') {
        if (currentToken.toString().trim().isNotEmpty) {
          tokens.add(currentToken.toString().trim());
          currentToken.clear();
        }
        tokens.add(char);
      } else if (char == ' ' || char == '\t' || char == '\n' || char == '\r') {
        if (currentToken.toString().trim().isNotEmpty) {
          tokens.add(currentToken.toString().trim());
          currentToken.clear();
        }
      } else {
        currentToken.write(char);
      }
    }

    if (currentToken.toString().trim().isNotEmpty) {
      tokens.add(currentToken.toString().trim());
    }

    if (tokens.isEmpty) return '';

    // Reconstruct with standard 2-space indentation
    final sb = StringBuffer();
    int indent = 0;
    bool lineStarted = false;
    bool inArgs = false;

    void writeIndent() {
      sb.write('  ' * indent);
    }

    for (int i = 0; i < tokens.length; i++) {
      final t = tokens[i];

      if (t.startsWith('#')) {
        if (lineStarted) sb.write('\n');
        writeIndent();
        sb.writeln(t);
        lineStarted = false;
        continue;
      }

      if (t == '{') {
        if (!lineStarted) {
          writeIndent();
        } else {
          sb.write(' ');
        }
        sb.write('{\n');
        indent++;
        lineStarted = false;
      } else if (t == '}') {
        if (lineStarted) {
          sb.write('\n');
        }
        indent = (indent - 1).clamp(0, 50);
        writeIndent();
        sb.write('}\n');
        lineStarted = false;
      } else if (t == '(') {
        inArgs = true;
        sb.write('(');
      } else if (t == ')') {
        inArgs = false;
        sb.write(')');
      } else if (t == ':') {
        sb.write(': ');
      } else if (t == ',') {
        sb.write(', ');
      } else {
        if (!lineStarted) {
          writeIndent();
          sb.write(t);
          lineStarted = true;
        } else {
          if (inArgs) {
            final prev = tokens[i - 1];
            if (prev != '(' && prev != ':' && prev != ',') {
              sb.write(' ');
            }
            sb.write(t);
          } else {
            final prev = tokens[i - 1];
            if (prev == 'query' ||
                prev == 'mutation' ||
                prev == 'subscription' ||
                prev == 'fragment' ||
                prev == 'on' ||
                prev == ')' ||
                prev.startsWith('"')) {
              sb.write(' $t');
            } else {
              sb.write('\n');
              writeIndent();
              sb.write(t);
            }
          }
        }
      }
    }

    return sb.toString().trim();
  }
}
