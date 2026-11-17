import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/api_request.dart';
import '../../domain/repositories/collection_repository.dart';
import '../models/api_request_model.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final String baseUrl = '${ApiConfig.baseUrl}/collections';

  @override
  Future<List<Collection>> getCollections() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) {
            final List rawRequests =
                item['requests'] is List ? item['requests'] : [];

            final List<ApiRequest> parsedRequests = rawRequests.map((req) {
              if (req is! Map) {
                return ApiRequest(
                  id: req.toString(),
                  method: HttpMethod.GET,
                  url: '',
                  headers: {},
                  params: {},
                );
              }

              // Extract Method safely
              HttpMethod method = HttpMethod.GET;
              final methodStr = req['method']?.toString().toUpperCase();
              for (final m in HttpMethod.values) {
                if (m.name.toUpperCase() == methodStr) {
                  method = m;
                  break;
                }
              }

              // Extract Headers safely
              final Map<String, String> headersMap = {};
              if (req['headers'] is List) {
                for (final h in req['headers']) {
                  if (h is Map && (h['enabled'] ?? true)) {
                    headersMap[h['key'].toString()] =
                        h['value']?.toString() ?? '';
                  }
                }
              } else if (req['headers'] is Map) {
                (req['headers'] as Map).forEach((k, v) {
                  headersMap[k.toString()] = v?.toString() ?? '';
                });
              }

              // Extract Params safely
              final Map<String, String> paramsMap = {};
              if (req['params'] is List) {
                for (final p in req['params']) {
                  if (p is Map && (p['enabled'] ?? true)) {
                    paramsMap[p['key'].toString()] =
                        p['value']?.toString() ?? '';
                  }
                }
              } else if (req['params'] is Map) {
                (req['params'] as Map).forEach((k, v) {
                  paramsMap[k.toString()] = v?.toString() ?? '';
                });
              }

              // Extract Body safely
              String? bodyContent;
              String bodyType = req['bodyType']?.toString() ?? 'none';
              if (req['body'] is Map) {
                bodyContent = req['body']['content']?.toString();
                bodyType = req['body']['type']?.toString() ?? bodyType;
              } else if (req['body'] is String) {
                bodyContent = req['body'];
              }

              return ApiRequest(
                id: req['_id']?.toString() ?? req['id']?.toString() ?? '',
                method: method,
                url: req['url']?.toString() ?? '',
                headers: headersMap,
                params: paramsMap,
                body: bodyContent,
                bodyType: bodyType,
                bodySubType: req['bodySubType']?.toString() ?? 'json',
                authType: req['authType']?.toString() ?? 'none',
                authDetails: req['authDetails'] is Map
                    ? Map<String, dynamic>.from(req['authDetails'])
                    : const {},
              );
            }).toList();

            return Collection(
              id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
              name: item['name']?.toString() ?? '',
              requests: parsedRequests,
            );
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> saveRequestToCollection(
      String collectionId, ApiRequest request) async {
    final model = ApiRequestModel.fromEntity(request);
    await http.post(
      Uri.parse('$baseUrl/$collectionId/requests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(model.toJson()),
    );
  }

  @override
  Future<String?> createCollection(String name) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data is Map) {
        return data['_id']?.toString() ?? data['id']?.toString();
      }
    }
    return null;
  }
}
