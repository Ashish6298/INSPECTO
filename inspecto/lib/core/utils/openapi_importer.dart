import 'dart:convert';
import '../../domain/entities/api_request.dart';
import 'postman_importer.dart';

class OpenApiImporter {
  /// Parses OpenAPI 3.0.x / Swagger 2.0 JSON string into [ImportedCollection].
  static ImportedCollection parse(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid OpenAPI specification: root must be a JSON object');
    }

    // 1. Title & Description
    final info = decoded['info'] is Map<String, dynamic>
        ? decoded['info'] as Map<String, dynamic>
        : <String, dynamic>{};

    final title = info['title']?.toString().trim().isNotEmpty == true
        ? info['title'].toString().trim()
        : 'Imported OpenAPI Collection';
    final description = info['description']?.toString();

    // 2. Base Server URL
    String baseUrl = '';
    if (decoded['servers'] is List && (decoded['servers'] as List).isNotEmpty) {
      final firstServer = (decoded['servers'] as List).first;
      if (firstServer is Map) {
        baseUrl = firstServer['url']?.toString() ?? '';
      }
    } else if (decoded['host'] != null) {
      // Swagger 2.0 fallback
      final scheme = (decoded['schemes'] is List && (decoded['schemes'] as List).isNotEmpty)
          ? (decoded['schemes'] as List).first.toString()
          : 'https';
      final host = decoded['host'].toString();
      final basePath = decoded['basePath']?.toString() ?? '';
      baseUrl = '$scheme://$host$basePath';
    }

    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    final List<ApiRequest> requests = [];

    // 3. Paths & Operations
    final paths = decoded['paths'];
    if (paths is Map<String, dynamic>) {
      for (final pathEntry in paths.entries) {
        final pathStr = pathEntry.key;
        if (pathEntry.value is! Map<String, dynamic>) continue;
        final pathItem = pathEntry.value as Map<String, dynamic>;

        // Path-level parameters
        final List<dynamic> pathLevelParams =
            pathItem['parameters'] is List ? pathItem['parameters'] as List : [];

        for (final opEntry in pathItem.entries) {
          final methodStr = opEntry.key.toUpperCase();
          HttpMethod? httpMethod;
          for (final m in HttpMethod.values) {
            if (m.name.toUpperCase() == methodStr) {
              httpMethod = m;
              break;
            }
          }
          if (httpMethod == null) continue; // Skip non-HTTP verbs (e.g. 'parameters', 'summary')

          if (opEntry.value is! Map<String, dynamic>) continue;
          final op = opEntry.value as Map<String, dynamic>;

          final req = _parseOperation(
            method: httpMethod,
            path: pathStr,
            baseUrl: baseUrl,
            operation: op,
            inheritedParams: pathLevelParams,
          );
          requests.add(req);
        }
      }
    }

    return ImportedCollection(
      name: title,
      description: description,
      requests: requests,
    );
  }

  static ApiRequest _parseOperation({
    required HttpMethod method,
    required String path,
    required String baseUrl,
    required Map<String, dynamic> operation,
    required List<dynamic> inheritedParams,
  }) {
    // Convert {id} to {{id}} for Inspecto environment variable alignment
    final normalizedPath = path.replaceAllMapped(
      RegExp(r'\{([^{}]+)\}'),
      (m) => '{{${m.group(1)}}}',
    );

    final fullUrl = baseUrl.isNotEmpty
        ? '$baseUrl$normalizedPath'
        : normalizedPath.startsWith('/')
            ? '{{baseUrl}}$normalizedPath'
            : '{{baseUrl}}/$normalizedPath';

    final Map<String, String> headers = {};
    final Map<String, String> params = {};

    // Combine inherited and operation parameters
    final allParams = <dynamic>[...inheritedParams];
    if (operation['parameters'] is List) {
      allParams.addAll(operation['parameters'] as List);
    }

    for (final p in allParams) {
      if (p is! Map) continue;
      final name = p['name']?.toString() ?? '';
      final inLoc = p['in']?.toString().toLowerCase() ?? '';
      final example = p['example']?.toString() ??
          p['schema']?['example']?.toString() ??
          p['schema']?['default']?.toString() ??
          '';

      if (name.isEmpty) continue;

      if (inLoc == 'query') {
        params[name] = example;
      } else if (inLoc == 'header') {
        headers[name] = example;
      }
    }

    // Request Body
    String? bodyContent;
    String bodyType = 'none';
    String bodySubType = 'json';

    final requestBody = operation['requestBody'];
    if (requestBody is Map<String, dynamic>) {
      final content = requestBody['content'];
      if (content is Map<String, dynamic>) {
        if (content.containsKey('application/json')) {
          bodyType = 'json';
          bodySubType = 'json';
          headers['Content-Type'] = 'application/json';

          final jsonContent = content['application/json'];
          if (jsonContent is Map) {
            final example = jsonContent['example'] ??
                jsonContent['schema']?['example'] ??
                _generateSampleFromSchema(jsonContent['schema']);

            if (example != null) {
              bodyContent = const JsonEncoder.withIndent('  ').convert(example);
            }
          }
        } else if (content.containsKey('application/x-www-form-urlencoded')) {
          bodyType = 'x-www-form-urlencoded';
          headers['Content-Type'] = 'application/x-www-form-urlencoded';
        } else if (content.containsKey('multipart/form-data')) {
          bodyType = 'form-data';
          headers['Content-Type'] = 'multipart/form-data';
        }
      }
    }

    // Security/Auth detection
    String authType = 'none';
    final Map<String, dynamic> authDetails = {};

    final security = operation['security'] ?? [];
    if (security is List && security.isNotEmpty) {
      // Default to bearer token placeholder if security requirement present
      authType = 'bearer';
      authDetails['token'] = '{{authToken}}';
    }

    return ApiRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      url: fullUrl,
      headers: headers,
      params: params,
      body: bodyContent,
      bodyType: bodyType,
      bodySubType: bodySubType,
      authType: authType,
      authDetails: authDetails,
    );
  }

  static dynamic _generateSampleFromSchema(dynamic schema) {
    if (schema is! Map) return null;

    final type = schema['type']?.toString();
    if (type == 'object' || schema.containsKey('properties')) {
      final properties = schema['properties'];
      if (properties is Map) {
        final Map<String, dynamic> result = {};
        for (final entry in properties.entries) {
          if (entry.value is Map) {
            final prop = entry.value as Map;
            result[entry.key.toString()] = prop['example'] ??
                prop['default'] ??
                (prop['type'] == 'string'
                    ? 'string'
                    : prop['type'] == 'integer' || prop['type'] == 'number'
                        ? 0
                        : prop['type'] == 'boolean'
                            ? false
                            : null);
          }
        }
        return result;
      }
    }

    return null;
  }
}
