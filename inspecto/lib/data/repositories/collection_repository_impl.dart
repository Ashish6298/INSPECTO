import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/collection.dart';
import '../../domain/entities/api_request.dart';
import '../../domain/repositories/collection_repository.dart';
import '../models/api_request_model.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final String baseUrl = 'http://10.0.2.2:5000/api/collections';

  @override
  Future<List<Collection>> getCollections() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((item) => Collection(
                id: item['_id'],
                name: item['name'],
                requests: (item['requests'] as List)
                    .map((req) => ApiRequest(
                          id: req['id'] ?? '',
                          method: HttpMethod.values.firstWhere((e) =>
                              e.toString().split('.').last == req['method']),
                          url: req['url'],
                          headers:
                              Map<String, String>.from(req['headers'] ?? {}),
                          params: Map<String, String>.from(req['params'] ?? {}),
                          body: req['body'],
                          bodyType: req['bodyType'] ?? 'none',
                        ))
                    .toList(),
              ))
          .toList();
    }
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
  Future<void> createCollection(String name) async {
    await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
  }
}
