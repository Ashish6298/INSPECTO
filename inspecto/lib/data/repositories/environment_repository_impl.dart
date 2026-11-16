import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../domain/entities/environment.dart';
import '../../domain/repositories/environment_repository.dart';

class EnvironmentRepositoryImpl implements EnvironmentRepository {
  final String baseUrl = '${ApiConfig.baseUrl}/environments';

  @override
  Future<List<Environment>> getEnvironments() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((item) {
            final rawVars = item['variables'];
            final List<EnvironmentVariable> varList = [];
            final Map<String, String> varMap = {};

            if (rawVars is List) {
              for (final v in rawVars) {
                if (v is Map) {
                  final key = v['key']?.toString() ?? '';
                  final val = v['value']?.toString() ?? '';
                  final enabled = v['enabled'] ?? true;
                  if (key.isNotEmpty) {
                    varList.add(EnvironmentVariable(
                      key: key,
                      value: val,
                      enabled: enabled,
                    ));
                    if (enabled) {
                      varMap[key] = val;
                    }
                  }
                }
              }
            } else if (rawVars is Map) {
              rawVars.forEach((k, v) {
                final key = k.toString();
                final val = v.toString();
                varList.add(EnvironmentVariable(key: key, value: val, enabled: true));
                varMap[key] = val;
              });
            }

            return Environment(
              id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
              name: item['name']?.toString() ?? '',
              variables: varMap,
              variableList: varList,
              isActive: item['isActive'] ?? false,
            );
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> saveEnvironment(Environment environment) async {
    final payload = {
      'name': environment.name,
      'variables': environment.variableList.map((v) => v.toJson()).toList(),
      'isActive': environment.isActive,
    };

    if (environment.id.length > 15) {
      // Assuming generated ID is short timestamp, MongoDB ID is long hex
      await http.put(
        Uri.parse('$baseUrl/${environment.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } else {
      await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    }
  }

  @override
  Future<void> deleteEnvironment(String id) async {
    await http.delete(Uri.parse('$baseUrl/$id'));
  }
}
