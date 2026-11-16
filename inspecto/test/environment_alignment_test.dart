import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspecto/domain/entities/environment.dart';
import 'package:inspecto/domain/entities/api_response.dart';

void main() {
  group('Phase 1.2: Environment Variable Schema & Alignment Tests', () {
    test('Environment entity synchronizes Map and List bidirectionally', () {
      final env = Environment(
        id: 'env_1',
        name: 'Production',
        variables: {
          'baseUrl': 'https://api.inspecto.dev',
          'apiKey': 'prod_key_123',
        },
      );

      expect(env.variables['baseUrl'], equals('https://api.inspecto.dev'));
      expect(env.variableList.length, equals(2));
      expect(env.variableList.first.key, equals('baseUrl'));
      expect(env.variableList.first.value, equals('https://api.inspecto.dev'));
      expect(env.variableList.first.enabled, isTrue);

      final serializedList = env.variableList.map((v) => v.toJson()).toList();
      expect(serializedList.length, equals(2));
      expect(serializedList.first['key'], equals('baseUrl'));
    });

    test('Environment entity parses from Backend array structure correctly', () {
      final backendJson = {
        '_id': '65c4a1b2c3d4e5f6a7b8c9d0',
        'name': 'Staging',
        'variables': [
          {'key': 'api.domain', 'value': 'staging.inspecto.dev', 'enabled': true},
          {'key': 'auth.token', 'value': 'bearer_token_xyz', 'enabled': true},
          {'key': 'deprecated_flag', 'value': 'false', 'enabled': false},
        ],
        'isActive': true,
      };

      final rawVars = backendJson['variables'] as List;
      final List<EnvironmentVariable> varList = [];
      final Map<String, String> varMap = {};

      for (final v in rawVars) {
        final ev = EnvironmentVariable.fromJson(Map<String, dynamic>.from(v));
        varList.add(ev);
        if (ev.enabled) {
          varMap[ev.key] = ev.value;
        }
      }

      final env = Environment(
        id: backendJson['_id'] as String,
        name: backendJson['name'] as String,
        variables: varMap,
        variableList: varList,
        isActive: backendJson['isActive'] as bool,
      );

      expect(env.id, equals('65c4a1b2c3d4e5f6a7b8c9d0'));
      expect(env.name, equals('Staging'));
      // Enabled vars present in map
      expect(env.variables['api.domain'], equals('staging.inspecto.dev'));
      expect(env.variables['auth.token'], equals('bearer_token_xyz'));
      // Disabled var omitted from active map
      expect(env.variables.containsKey('deprecated_flag'), isFalse);
      // But preserved in full list
      expect(env.variableList.length, equals(3));
      expect(env.isActive, isTrue);
    });

    test('ApiResponse handles multi-value response headers (e.g. set-cookie)', () {
      final rawBackendResponse = {
        'status': 200,
        'headers': {
          'content-type': 'application/json',
          'set-cookie': [
            'session_id=abc12345; Path=/; HttpOnly',
            'user_pref=dark; Path=/'
          ],
          'x-rate-limit': 100,
        },
        'data': {'success': true},
      };

      final Map<String, String> headers = {};
      (rawBackendResponse['headers'] as Map).forEach((k, v) {
        headers[k.toString()] = v is List ? v.join(', ') : v.toString();
      });

      final apiResponse = ApiResponse(
        statusCode: rawBackendResponse['status'] as int,
        body: jsonEncode(rawBackendResponse['data']),
        headers: headers,
        responseTimeMs: 85,
        responseSize: 128,
      );

      expect(apiResponse.statusCode, equals(200));
      expect(apiResponse.headers['content-type'], equals('application/json'));
      expect(
        apiResponse.headers['set-cookie'],
        equals('session_id=abc12345; Path=/; HttpOnly, user_pref=dark; Path=/'),
      );
      expect(apiResponse.headers['x-rate-limit'], equals('100'));
      expect(apiResponse.isSuccess, isTrue);
    });
  });
}
