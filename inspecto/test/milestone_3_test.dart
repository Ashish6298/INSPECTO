import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspecto/domain/entities/api_request.dart';
import 'package:inspecto/domain/entities/api_response.dart';
import 'package:inspecto/domain/entities/environment.dart';
import 'package:inspecto/domain/entities/variable_extractor.dart';
import 'package:inspecto/core/utils/postman_importer.dart';
import 'package:inspecto/core/utils/openapi_importer.dart';
import 'package:inspecto/domain/repositories/environment_repository.dart';
import 'package:inspecto/presentation/providers/environment_provider.dart';

class MockEnvironmentRepository implements EnvironmentRepository {
  final Map<String, Environment> envs = {};

  @override
  Future<List<Environment>> getEnvironments() async {
    return envs.values.toList();
  }

  @override
  Future<void> saveEnvironment(Environment environment) async {
    envs[environment.id] = environment;
  }

  @override
  Future<void> deleteEnvironment(String id) async {
    envs.remove(id);
  }
}

void main() {
  group('Phase 3.0: Variable Extractor Unit Tests', () {
    test('Extracts simple and nested JSONPath fields from response body', () {
      final response = ApiResponse(
        statusCode: 200,
        body: jsonEncode({
          'token': 'root_jwt_token',
          'data': {
            'user': {
              'id': 'usr_987',
              'email': 'developer@inspecto.dev',
            },
            'accessToken': 'nested_jwt_token',
          },
        }),
        headers: {},
        responseTimeMs: 50,
        responseSize: 200,
      );

      final extRoot = VariableExtractor(
        id: '1',
        source: ExtractorSource.responseBody,
        pathOrKey: 'token',
        targetVariable: 'jwt',
      );
      expect(VariableExtractor.extractFromResponse(extRoot, response),
          equals('root_jwt_token'));

      final extNested = VariableExtractor(
        id: '2',
        source: ExtractorSource.responseBody,
        pathOrKey: 'data.accessToken',
        targetVariable: 'authToken',
      );
      expect(VariableExtractor.extractFromResponse(extNested, response),
          equals('nested_jwt_token'));

      final extDeep = VariableExtractor(
        id: '3',
        source: ExtractorSource.responseBody,
        pathOrKey: 'data.user.id',
        targetVariable: 'userId',
      );
      expect(VariableExtractor.extractFromResponse(extDeep, response),
          equals('usr_987'));
    });

    test('Extracts array items by index (both [0] and .0 notation)', () {
      final response = ApiResponse(
        statusCode: 200,
        body: jsonEncode({
          'items': [
            {'id': 'item_0', 'name': 'First Item'},
            {'id': 'item_1', 'name': 'Second Item'},
          ],
        }),
        headers: {},
        responseTimeMs: 40,
        responseSize: 150,
      );

      final extBracket = VariableExtractor(
        id: '1',
        source: ExtractorSource.responseBody,
        pathOrKey: 'items[0].id',
        targetVariable: 'firstId',
      );
      expect(VariableExtractor.extractFromResponse(extBracket, response),
          equals('item_0'));

      final extDot = VariableExtractor(
        id: '2',
        source: ExtractorSource.responseBody,
        pathOrKey: 'items.1.name',
        targetVariable: 'secondName',
      );
      expect(VariableExtractor.extractFromResponse(extDot, response),
          equals('Second Item'));
    });

    test('Extracts values from Response Headers (case-insensitive & Bearer prefix stripping)', () {
      final response = ApiResponse(
        statusCode: 200,
        body: '{"status":"ok"}',
        headers: {
          'Authorization': 'Bearer sample_header_jwt_token',
          'X-Custom-Request-Id': 'req-abc-xyz',
        },
        responseTimeMs: 35,
        responseSize: 100,
      );

      final extAuth = VariableExtractor(
        id: '1',
        source: ExtractorSource.responseHeader,
        pathOrKey: 'authorization',
        targetVariable: 'authToken',
      );
      expect(VariableExtractor.extractFromResponse(extAuth, response),
          equals('sample_header_jwt_token'));

      final extCustom = VariableExtractor(
        id: '2',
        source: ExtractorSource.responseHeader,
        pathOrKey: 'x-custom-request-id',
        targetVariable: 'traceId',
      );
      expect(VariableExtractor.extractFromResponse(extCustom, response),
          equals('req-abc-xyz'));
    });

    test('Returns null if extractor is disabled or key path does not exist', () {
      final response = ApiResponse(
        statusCode: 200,
        body: '{"token":"123"}',
        headers: {},
        responseTimeMs: 20,
        responseSize: 50,
      );

      final extDisabled = VariableExtractor(
        id: '1',
        source: ExtractorSource.responseBody,
        pathOrKey: 'token',
        targetVariable: 'authToken',
        enabled: false,
      );
      expect(VariableExtractor.extractFromResponse(extDisabled, response), isNull);

      final extMissing = VariableExtractor(
        id: '2',
        source: ExtractorSource.responseBody,
        pathOrKey: 'non_existent_key',
        targetVariable: 'authToken',
      );
      expect(VariableExtractor.extractFromResponse(extMissing, response), isNull);
    });

    test('Dynamic Environment Chaining updates EnvironmentProvider variable', () async {
      final mockRepo = MockEnvironmentRepository();
      final initialEnv = Environment(
        id: 'env_dev',
        name: 'Development',
        variables: {'baseUrl': 'https://api.dev.inspecto'},
      );
      await mockRepo.saveEnvironment(initialEnv);

      final envProvider = EnvironmentProvider(repository: mockRepo);
      await envProvider.loadEnvironments();
      envProvider.setActiveEnvironment(initialEnv);

      expect(envProvider.activeEnvironment?.variables['authToken'], isNull);

      // Simulate post-response extraction update
      await envProvider.updateVariable('env_dev', 'authToken', 'newly_extracted_jwt');

      expect(envProvider.activeEnvironment?.variables['authToken'],
          equals('newly_extracted_jwt'));
      expect(envProvider.activeEnvironment?.variables['baseUrl'],
          equals('https://api.dev.inspecto'));
    });
  });

  group('Phase 3.1: Postman Collection Importer Tests', () {
    const postmanJson = '''
{
  "info": {
    "name": "Inspecto Auth & User API",
    "description": "Collection for testing authentication and users",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [
              { "key": "Content-Type", "value": "application/json" }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\\"username\\": \\"admin\\", \\"password\\": \\"secret\\"}",
              "options": { "raw": { "language": "json" } }
            },
            "url": {
              "raw": "{{baseUrl}}/auth/login",
              "host": ["{{baseUrl}}"],
              "path": ["auth", "login"]
            }
          }
        }
      ]
    },
    {
      "name": "Get Profile",
      "request": {
        "method": "GET",
        "header": [
          { "key": "Accept", "value": "application/json" }
        ],
        "auth": {
          "type": "bearer",
          "bearer": [
            { "key": "token", "value": "{{authToken}}", "type": "string" }
          ]
        },
        "url": {
          "raw": "{{baseUrl}}/users/profile?include=avatar",
          "query": [
            { "key": "include", "value": "avatar" }
          ]
        }
      }
    }
  ]
}
''';

    test('Parses Postman v2.1 collection with folders, headers, body, and auth', () {
      final imported = PostmanImporter.parse(postmanJson);

      expect(imported.name, equals('Inspecto Auth & User API'));
      expect(imported.description, contains('authentication and users'));
      expect(imported.requests.length, equals(2));

      // Request 1: POST Login inside folder Auth
      final req1 = imported.requests[0];
      expect(req1.method, equals(HttpMethod.POST));
      expect(req1.url, equals('{{baseUrl}}/auth/login'));
      expect(req1.headers['Content-Type'], equals('application/json'));
      expect(req1.bodyType, equals('json'));
      expect(req1.body, contains('"username": "admin"'));

      // Request 2: GET Profile with Bearer auth and query params
      final req2 = imported.requests[1];
      expect(req2.method, equals(HttpMethod.GET));
      expect(req2.url, contains('{{baseUrl}}/users/profile'));
      expect(req2.params['include'], equals('avatar'));
      expect(req2.authType, equals('bearer'));
      expect(req2.authDetails?['token'], equals('{{authToken}}'));
    });
  });

  group('Phase 3.1: OpenAPI / Swagger Spec Importer Tests', () {
    const openApiJson = '''
{
  "openapi": "3.0.1",
  "info": {
    "title": "Swagger Petstore",
    "description": "A sample API for testing OpenAPI imports",
    "version": "1.0.0"
  },
  "servers": [
    { "url": "https://api.petstore.io/v2" }
  ],
  "paths": {
    "/pets": {
      "get": {
        "summary": "List all pets",
        "parameters": [
          { "name": "limit", "in": "query", "example": "20" }
        ]
      },
      "post": {
        "summary": "Create a pet",
        "requestBody": {
          "content": {
            "application/json": {
              "example": { "name": "Fluffy", "tag": "cat" }
            }
          }
        },
        "security": [
          { "bearerAuth": [] }
        ]
      }
    },
    "/pets/{petId}": {
      "delete": {
        "summary": "Delete pet by ID",
        "parameters": [
          { "name": "petId", "in": "path" }
        ]
      }
    }
  }
}
''';

    test('Parses OpenAPI 3.0 spec with servers, operations, path variables, and body examples', () {
      final imported = OpenApiImporter.parse(openApiJson);

      expect(imported.name, equals('Swagger Petstore'));
      expect(imported.description, contains('sample API for testing'));
      expect(imported.requests.length, equals(3));

      // Request 1: GET /pets with query parameter
      final getReq = imported.requests.firstWhere(
          (r) => r.method == HttpMethod.GET && r.url.endsWith('/pets'));
      expect(getReq.url, equals('https://api.petstore.io/v2/pets'));
      expect(getReq.params['limit'], equals('20'));

      // Request 2: POST /pets with JSON sample body and bearer auth
      final postReq = imported.requests.firstWhere(
          (r) => r.method == HttpMethod.POST && r.url.endsWith('/pets'));
      expect(postReq.bodyType, equals('json'));
      expect(postReq.headers['Content-Type'], equals('application/json'));
      expect(postReq.body, contains('"name": "Fluffy"'));
      expect(postReq.authType, equals('bearer'));

      // Request 3: DELETE /pets/{{petId}} with path parameter converted
      final deleteReq = imported.requests.firstWhere(
          (r) => r.method == HttpMethod.DELETE);
      expect(deleteReq.url, equals('https://api.petstore.io/v2/pets/{{petId}}'));
    });
  });
}
