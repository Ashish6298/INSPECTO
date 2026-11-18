import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:inspecto/domain/entities/api_request.dart';
import 'package:inspecto/domain/entities/api_response.dart';
import 'package:inspecto/data/datasources/sse_stream_data_source.dart';
import 'package:inspecto/data/datasources/websocket_data_source.dart';
import 'package:inspecto/data/datasources/api_direct_data_source.dart';
import 'package:inspecto/data/models/api_request_model.dart';
import 'package:inspecto/core/utils/graphql_introspection.dart';
import 'package:inspecto/presentation/providers/websocket_provider.dart';
import 'package:inspecto/presentation/providers/request_provider.dart';
import 'package:inspecto/domain/repositories/api_repository.dart';

class MockStreamHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;

  MockStreamHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return handler(request);
  }
}

class DummyApiRepository implements ApiRepository {
  @override
  Future<ApiResponse> executeRequest(ApiRequest request) async {
    return ApiResponse(
      statusCode: 200,
      body: 'ok',
      headers: {},
      responseTimeMs: 10,
      responseSize: 2,
    );
  }
}

class MockWebSocketDataSource extends WebSocketDataSource {
  final StreamController<WebSocketStatus> _testStatusController =
      StreamController<WebSocketStatus>.broadcast();
  final StreamController<WebSocketFrame> _testFrameController =
      StreamController<WebSocketFrame>.broadcast();
  WebSocketStatus _testStatus = WebSocketStatus.disconnected;

  @override
  WebSocketStatus get currentStatus => _testStatus;

  @override
  Stream<WebSocketStatus> get statusStream => _testStatusController.stream;

  @override
  Stream<WebSocketFrame> get frameStream => _testFrameController.stream;

  @override
  Future<void> connect(String url) async {
    _testStatus = WebSocketStatus.connected;
    _testStatusController.add(WebSocketStatus.connected);
  }

  @override
  void send(String message) {
    // Emit outbound frame
    final outFrame = WebSocketFrame(
      id: 'out_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now(),
      isInbound: false,
      payload: message,
      byteLength: message.length,
    );
    _testFrameController.add(outFrame);

    // Simulate echo response for tests
    final inFrame = WebSocketFrame(
      id: 'in_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now(),
      isInbound: true,
      payload: 'echo: $message',
      byteLength: 'echo: $message'.length,
    );
    _testFrameController.add(inFrame);
  }

  @override
  Future<void> disconnect({int? closeCode, String? closeReason}) async {
    _testStatus = WebSocketStatus.disconnected;
    _testStatusController.add(WebSocketStatus.disconnected);
  }

  @override
  void dispose() {
    _testStatusController.close();
    _testFrameController.close();
  }
}

void main() {
  group('Phase 4.0: SSE & LLM Streaming Tests', () {
    test('extractLlmDelta accurately parses OpenAI, Gemini, Ollama, and Anthropic payloads', () {
      // 1. OpenAI delta
      const openAiChunk =
          '{"id":"chatcmpl-1","choices":[{"delta":{"content":"Hello world!"}}]}';
      expect(SseStreamDataSource.extractLlmDelta(openAiChunk), equals('Hello world!'));

      // 2. Google Gemini delta
      const geminiChunk =
          '{"candidates":[{"content":{"parts":[{"text":"Gemini output"}]}}]}';
      expect(SseStreamDataSource.extractLlmDelta(geminiChunk), equals('Gemini output'));

      // 3. Ollama delta
      const ollamaChunk = '{"response":"Ollama token stream"}';
      expect(SseStreamDataSource.extractLlmDelta(ollamaChunk),
          equals('Ollama token stream'));

      // 4. Anthropic delta
      const anthropicChunk = '{"type":"content_block_delta","delta":{"text":"Claude AI"}}';
      expect(SseStreamDataSource.extractLlmDelta(anthropicChunk), equals('Claude AI'));

      // 5. Termination token
      expect(SseStreamDataSource.extractLlmDelta('[DONE]'), equals(''));

      // 6. Plain text fallback
      expect(SseStreamDataSource.extractLlmDelta('Raw plain text chunk'),
          equals('Raw plain text chunk'));
    });

    test('SseStreamDataSource streams chunks and terminates on [DONE]', () async {
      final sseStreamData = [
        'data: {"choices":[{"delta":{"content":"Inspecto"}}]}\n\n',
        'data: {"choices":[{"delta":{"content":" Streaming"}}]}\n\n',
        ': keepalive ping\n\n',
        'data: [DONE]\n\n',
      ];

      final mockClient = MockStreamHttpClient((request) async {
        return http.StreamedResponse(
          Stream.fromIterable(sseStreamData.map(utf8.encode)),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });

      final dataSource = SseStreamDataSource(client: mockClient);
      final request = ApiRequest(
        id: 'req_sse',
        method: HttpMethod.POST,
        url: 'https://api.openai.com/v1/chat/completions',
        headers: {'Content-Type': 'application/json'},
        params: {},
        body: '{"stream":true}',
      );

      final events = await dataSource.streamRequest(request).toList();
      expect(events.length, equals(3));
      expect(events[0].data, contains('Inspecto'));
      expect(events[1].data, contains('Streaming'));
      expect(events[2].isDone, isTrue);
    });

    test('RequestProvider streams SSE events and can be stopped', () async {
      final sseStreamData = [
        'data: {"choices":[{"delta":{"content":"First chunk"}}]}\n\n',
        'data: {"choices":[{"delta":{"content":" Second chunk"}}]}\n\n',
        'data: [DONE]\n\n',
      ];

      final mockClient = MockStreamHttpClient((request) async {
        return http.StreamedResponse(
          Stream.fromIterable(sseStreamData.map(utf8.encode)),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });

      final provider = RequestProvider(apiRepository: DummyApiRepository());
      provider.sseDataSource = SseStreamDataSource(client: mockClient);
      provider.setUrl('https://api.ai.com/stream');
      provider.setStreamMode(true);

      expect(provider.isStreamMode, isTrue);
      expect(provider.isStreaming, isFalse);

      await provider.sendRequest();

      expect(provider.isStreaming, isFalse);
      expect(provider.streamedText, contains('First chunk'));
      expect(provider.streamedText, contains('Second chunk'));
      expect(provider.streamChunks, greaterThanOrEqualTo(2));
      expect(provider.response, isNotNull);
      expect(provider.response?.headers['content-type'],
          equals('text/event-stream'));
    });
  });

  group('Phase 4.1: WebSocket Client Tests', () {
    test('WebSocketFrame serializes and deserializes accurately', () {
      final now = DateTime.now();
      final frame = WebSocketFrame(
        id: 'f_101',
        timestamp: now,
        isInbound: true,
        payload: '{"status":"connected"}',
        byteLength: 22,
      );

      final json = frame.toJson();
      final restored = WebSocketFrame.fromJson(json);

      expect(restored.id, equals('f_101'));
      expect(restored.isInbound, isTrue);
      expect(restored.payload, equals('{"status":"connected"}'));
      expect(restored.byteLength, equals(22));
    });

    test('WebSocketProvider manages connection lifecycle, frames, and filters', () async {
      final mockSource = MockWebSocketDataSource();
      final provider = WebSocketProvider(dataSource: mockSource);

      expect(provider.status, equals(WebSocketStatus.disconnected));
      expect(provider.frames, isEmpty);

      // Connect
      await provider.connect();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.status, equals(WebSocketStatus.connected));

      // Send message
      provider.sendMessage('Ping from client');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.frames.length, equals(2)); // 1 Outbound + 1 Echo Inbound
      expect(provider.inboundCount, equals(1));
      expect(provider.outboundCount, equals(1));

      // Test Filters
      provider.setFilter('inbound');
      expect(provider.filteredFrames.length, equals(1));
      expect(provider.filteredFrames.first.isInbound, isTrue);

      provider.setFilter('outbound');
      expect(provider.filteredFrames.length, equals(1));
      expect(provider.filteredFrames.first.isInbound, isFalse);

      provider.setFilter('all');
      expect(provider.filteredFrames.length, equals(2));

      // Test Search Query
      provider.setSearchQuery('echo');
      expect(provider.filteredFrames.length, equals(1));
      expect(provider.filteredFrames.first.payload, contains('echo:'));

      // Clear Frames
      provider.clearFrames();
      expect(provider.frames, isEmpty);

      // Disconnect
      await provider.disconnect();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.status, equals(WebSocketStatus.disconnected));
    });
  });

  group('Phase 4.2: Dedicated GraphQL Query & Schema Explorer Tests', () {
    test('formatGraphQL correctly auto-indents single-line and unformatted GraphQL queries', () {
      const minified =
          'query GetUser(\$id: ID!) { user(id: \$id) { id name posts { id title } } }';
      final formatted = GraphQLIntrospection.formatGraphQL(minified);

      expect(formatted, contains('query GetUser(\$id: ID!) {'));
      expect(formatted, contains('  user(id: \$id) {'));
      expect(formatted, contains('    id'));
      expect(formatted, contains('    name'));
      expect(formatted, contains('    posts {'));
      expect(formatted, contains('      id'));
      expect(formatted, contains('      title'));
      expect(formatted, contains('    }'));
      expect(formatted, contains('  }'));
      expect(formatted.endsWith('}'), isTrue);
    });

    test('buildPayload packs query and variables into standard GraphQL HTTP payload', () {
      const query = 'query { users { id } }';
      const variables = '{"limit": 25, "active": true}';

      final payload = GraphQLIntrospection.buildPayload(query, variables);
      final decoded = jsonDecode(payload) as Map<String, dynamic>;

      expect(decoded['query'], equals(query));
      expect(decoded['variables'], equals({'limit': 25, 'active': true}));
    });

    test('buildPayload handles empty or malformed variables gracefully', () {
      const query = 'query { hello }';
      final payloadEmpty = GraphQLIntrospection.buildPayload(query, '');
      final decodedEmpty = jsonDecode(payloadEmpty) as Map<String, dynamic>;
      expect(decodedEmpty['query'], equals(query));
      expect(decodedEmpty['variables'], equals({}));

      final payloadInvalid = GraphQLIntrospection.buildPayload(query, '{not valid json}');
      final decodedInvalid = jsonDecode(payloadInvalid) as Map<String, dynamic>;
      expect(decodedInvalid['variables'], equals({}));
    });

    test('extractQueryAndVariables parses both JSON payloads and raw GraphQL strings', () {
      // 1. JSON payload
      final jsonPayload = jsonEncode({
        'query': 'query GetItems { items { id } }',
        'variables': {'filter': 'active'},
      });
      final fromJson = GraphQLIntrospection.extractQueryAndVariables(jsonPayload);
      expect(fromJson.query, equals('query GetItems { items { id } }'));
      expect(fromJson.variables, contains('"filter": "active"'));

      // 2. Raw query string
      const rawString = 'query { ping }';
      final fromRaw = GraphQLIntrospection.extractQueryAndVariables(rawString);
      expect(fromRaw.query, equals('query { ping }'));
      expect(fromRaw.variables, equals('{}'));

      // 3. Null / empty
      final fromNull = GraphQLIntrospection.extractQueryAndVariables(null);
      expect(fromNull.query, equals(''));
      expect(fromNull.variables, equals('{}'));
    });

    test('parseSchema parses __schema response into queries, mutations, and types', () {
      final sampleSchemaResponse = {
        'data': {
          '__schema': {
            'queryType': {'name': 'Query'},
            'mutationType': {'name': 'Mutation'},
            'types': [
              {
                'kind': 'OBJECT',
                'name': 'Query',
                'description': 'Root query',
                'fields': [
                  {
                    'name': 'users',
                    'description': 'Retrieve list of users',
                    'args': [
                      {
                        'name': 'limit',
                        'description': 'Max results',
                        'type': {'kind': 'SCALAR', 'name': 'Int', 'ofType': null},
                        'defaultValue': '10',
                      }
                    ],
                    'type': {
                      'kind': 'LIST',
                      'name': null,
                      'ofType': {
                        'kind': 'NON_NULL',
                        'name': null,
                        'ofType': {'kind': 'OBJECT', 'name': 'User', 'ofType': null},
                      },
                    },
                    'isDeprecated': false,
                  }
                ],
              },
              {
                'kind': 'OBJECT',
                'name': 'Mutation',
                'description': 'Root mutation',
                'fields': [
                  {
                    'name': 'createUser',
                    'description': 'Creates a user',
                    'args': [
                      {
                        'name': 'name',
                        'type': {
                          'kind': 'NON_NULL',
                          'name': null,
                          'ofType': {'kind': 'SCALAR', 'name': 'String', 'ofType': null},
                        },
                      }
                    ],
                    'type': {'kind': 'OBJECT', 'name': 'User', 'ofType': null},
                    'isDeprecated': false,
                  }
                ],
              },
              {
                'kind': 'OBJECT',
                'name': 'User',
                'description': 'User object',
                'fields': [
                  {
                    'name': 'id',
                    'type': {
                      'kind': 'NON_NULL',
                      'name': null,
                      'ofType': {'kind': 'SCALAR', 'name': 'ID', 'ofType': null},
                    },
                  },
                  {
                    'name': 'name',
                    'type': {'kind': 'SCALAR', 'name': 'String', 'ofType': null},
                  },
                ],
              },
              {
                'kind': 'OBJECT',
                'name': '__Schema',
                'fields': [],
              }
            ],
          }
        }
      };

      final doc = GraphQLIntrospection.parseSchema(sampleSchemaResponse);

      expect(doc.isNotEmpty, isTrue);
      expect(doc.queryTypeName, equals('Query'));
      expect(doc.mutationTypeName, equals('Mutation'));

      // Queries
      expect(doc.queries.length, equals(1));
      final userQuery = doc.queries.first;
      expect(userQuery.name, equals('users'));
      expect(userQuery.returnType, equals('[User!]'));
      expect(userQuery.signature, equals('users(limit: Int = 10): [User!]'));
      expect(userQuery.description, equals('Retrieve list of users'));

      // Snippet generation
      final querySnippet = userQuery.generateSnippet();
      expect(querySnippet, contains('query Users(\$limit: Int) {'));
      expect(querySnippet, contains('users(limit: \$limit) {'));

      // Mutations
      expect(doc.mutations.length, equals(1));
      final createMutation = doc.mutations.first;
      expect(createMutation.name, equals('createUser'));
      expect(createMutation.returnType, equals('User'));
      expect(createMutation.signature, equals('createUser(name: String!): User'));

      final mutationSnippet = createMutation.generateSnippet(isMutation: true);
      expect(mutationSnippet, contains('mutation CreateUser(\$name: String!) {'));

      // Types (Query and Mutation filtered out, __Schema ignored)
      expect(doc.types.length, equals(1));
      final userType = doc.types.first;
      expect(userType.name, equals('User'));
      expect(userType.kind, equals('OBJECT'));
      expect(userType.fields.length, equals(2));
      expect(userType.fields[0].name, equals('id'));
      expect(userType.fields[0].returnType, equals('ID!'));
    });

    test('ApiDirectDataSource auto-injects application/json Content-Type for GraphQL requests', () async {
      late http.Request sentRequest;

      final mockClient = MockStreamHttpClient((req) async {
        sentRequest = req as http.Request;
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"data":{"users":[]}}')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final dataSource = ApiDirectDataSource(client: mockClient);
      final request = ApiRequestModel(
        id: 'graphql_test',
        method: HttpMethod.POST,
        url: 'https://api.example.com/graphql',
        headers: {},
        params: {},
        body: jsonEncode({'query': 'query { users { id } }'}),
        bodyType: 'graphql',
        bodySubType: 'json',
      );

      final response = await dataSource.executeRequest(request);

      expect(response.statusCode, equals(200));
      expect(sentRequest.headers['Content-Type'], contains('application/json'));
    });
  });
}
