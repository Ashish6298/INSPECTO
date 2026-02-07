import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/environment.dart';
import '../../domain/repositories/environment_repository.dart';

class EnvironmentRepositoryImpl implements EnvironmentRepository {
  final String baseUrl = 'http://10.0.2.2:5000/api/environments';

  @override
  Future<List<Environment>> getEnvironments() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((item) => Environment(
                id: item['_id'],
                name: item['name'],
                variables: Map<String, String>.from(item['variables'] ?? {}),
              ))
          .toList();
    }
    return [];
  }

  @override
  Future<void> saveEnvironment(Environment environment) async {
    if (environment.id.length > 15) {
      // Assuming generated ID is short, MongoDB ID is long
      await http.put(
        Uri.parse('$baseUrl/${environment.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': environment.name,
          'variables': environment.variables,
        }),
      );
    } else {
      await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': environment.name,
          'variables': environment.variables,
        }),
      );
    }
  }

  @override
  Future<void> deleteEnvironment(String id) async {
    await http.delete(Uri.parse('$baseUrl/$id'));
  }
}
