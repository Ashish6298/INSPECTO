import 'dart:convert';
import '../../domain/entities/api_request.dart';

class ImportedCollection {
  final String name;
  final String? description;
  final List<ApiRequest> requests;

  ImportedCollection({
    required this.name,
    this.description,
    required this.requests,
  });
}

class PostmanImporter {
  /// Parses Postman Collection v2.0 or v2.1 JSON string into [ImportedCollection].
  static ImportedCollection parse(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Postman Collection: root must be a JSON object');
    }

    // Extract name & description
    final info = decoded['info'] is Map<String, dynamic>
        ? decoded['info'] as Map<String, dynamic>
        : <String, dynamic>{};

    final collectionName =
        info['name']?.toString().trim().isNotEmpty == true
            ? info['name'].toString().trim()
            : 'Imported Postman Collection';

    final description = info['description']?.toString();

    final List<ApiRequest> requests = [];
    final rawItems = decoded['item'];
    if (rawItems is List) {
      _extractItems(rawItems, requests, '');
    }

    return ImportedCollection(
      name: collectionName,
      description: description,
      requests: requests,
    );
  }

  static void _extractItems(
      List<dynamic> items, List<ApiRequest> result, String folderPrefix) {
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      final itemName = item['name']?.toString() ?? 'Request';
      final currentName =
          folderPrefix.isEmpty ? itemName : '$folderPrefix / $itemName';

      // Check if item is a folder (contains nested 'item' array)
      if (item['item'] is List) {
        _extractItems(item['item'] as List, result, currentName);
      } else if (item['request'] != null) {
        // It's a request!
        final parsed = _parseRequest(item['request'], currentName);
        if (parsed != null) {
          result.add(parsed);
        }
      }
    }
  }

  static ApiRequest? _parseRequest(dynamic reqData, String requestName) {
    if (reqData is String) {
      // Shorthand URL string request in Postman
      return ApiRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        method: HttpMethod.GET,
        url: reqData,
        headers: {},
        params: {},
      );
    }

    if (reqData is! Map<String, dynamic>) return null;

    // 1. Method
    HttpMethod method = HttpMethod.GET;
    final methodStr = reqData['method']?.toString().toUpperCase() ?? 'GET';
    for (final m in HttpMethod.values) {
      if (m.name.toUpperCase() == methodStr) {
        method = m;
        break;
      }
    }

    // 2. URL & Query Parameters
    String url = '';
    final Map<String, String> params = {};

    final rawUrl = reqData['url'];
    if (rawUrl is String) {
      url = rawUrl;
      _extractQueryParamsFromUrl(url, params);
    } else if (rawUrl is Map<String, dynamic>) {
      url = rawUrl['raw']?.toString() ?? '';

      // Fallback: reconstruct from components if raw is missing
      if (url.isEmpty) {
        final host = rawUrl['host'] is List
            ? (rawUrl['host'] as List).join('.')
            : rawUrl['host']?.toString() ?? '';
        final path = rawUrl['path'] is List
            ? (rawUrl['path'] as List).join('/')
            : rawUrl['path']?.toString() ?? '';
        final protocol = rawUrl['protocol']?.toString() ?? 'https';
        url = '$protocol://$host/$path';
      }

      // Query params array
      if (rawUrl['query'] is List) {
        for (final q in rawUrl['query']) {
          if (q is Map && (q['disabled'] != true)) {
            final k = q['key']?.toString() ?? '';
            final v = q['value']?.toString() ?? '';
            if (k.isNotEmpty) params[k] = v;
          }
        }
      }
    }

    // 3. Headers
    final Map<String, String> headers = {};
    if (reqData['header'] is List) {
      for (final h in reqData['header']) {
        if (h is Map && (h['disabled'] != true)) {
          final k = h['key']?.toString() ?? '';
          final v = h['value']?.toString() ?? '';
          if (k.isNotEmpty) headers[k] = v;
        }
      }
    }

    // 4. Body
    String? bodyContent;
    String bodyType = 'none';
    String bodySubType = 'json';

    final bodyData = reqData['body'];
    if (bodyData is Map<String, dynamic>) {
      final mode = bodyData['mode']?.toString();
      if (mode == 'raw') {
        bodyType = 'raw';
        bodyContent = bodyData['raw']?.toString();
        final lang =
            bodyData['options']?['raw']?['language']?.toString().toLowerCase();
        if (lang == 'json' ||
            (bodyContent != null &&
                bodyContent.trim().startsWith('{') &&
                bodyContent.trim().endsWith('}'))) {
          bodyType = 'json';
          bodySubType = 'json';
        } else if (lang != null) {
          bodySubType = lang;
        }
      } else if (mode == 'urlencoded') {
        bodyType = 'x-www-form-urlencoded';
        if (bodyData['urlencoded'] is List) {
          final pairs = <String>[];
          for (final pair in bodyData['urlencoded']) {
            if (pair is Map && (pair['disabled'] != true)) {
              final k = Uri.encodeQueryComponent(pair['key']?.toString() ?? '');
              final v =
                  Uri.encodeQueryComponent(pair['value']?.toString() ?? '');
              pairs.add('$k=$v');
            }
          }
          bodyContent = pairs.join('&');
        }
      } else if (mode == 'formdata') {
        bodyType = 'form-data';
      }
    }

    // 5. Auth
    String authType = 'none';
    final Map<String, dynamic> authDetails = {};

    final authData = reqData['auth'];
    if (authData is Map<String, dynamic>) {
      final type = authData['type']?.toString().toLowerCase();
      if (type == 'bearer') {
        authType = 'bearer';
        final bearerList = authData['bearer'];
        if (bearerList is List) {
          for (final b in bearerList) {
            if (b is Map && b['key'] == 'token') {
              authDetails['token'] = b['value']?.toString() ?? '';
            }
          }
        }
      } else if (type == 'basic') {
        authType = 'basic';
        final basicList = authData['basic'];
        if (basicList is List) {
          for (final b in basicList) {
            if (b is Map) {
              if (b['key'] == 'username') {
                authDetails['username'] = b['value']?.toString() ?? '';
              } else if (b['key'] == 'password') {
                authDetails['password'] = b['value']?.toString() ?? '';
              }
            }
          }
        }
      } else if (type == 'apikey') {
        authType = 'apiKey';
        final apiList = authData['apikey'];
        if (apiList is List) {
          for (final a in apiList) {
            if (a is Map) {
              if (a['key'] == 'key') {
                authDetails['key'] = a['value']?.toString() ?? '';
              } else if (a['key'] == 'value') {
                authDetails['value'] = a['value']?.toString() ?? '';
              }
            }
          }
        }
      }
    }

    return ApiRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      url: url,
      headers: headers,
      params: params,
      body: bodyContent,
      bodyType: bodyType,
      bodySubType: bodySubType,
      authType: authType,
      authDetails: authDetails,
    );
  }

  static void _extractQueryParamsFromUrl(
      String url, Map<String, String> params) {
    try {
      final uri = Uri.parse(url);
      uri.queryParameters.forEach((k, v) {
        params[k] = v;
      });
    } catch (_) {}
  }
}
