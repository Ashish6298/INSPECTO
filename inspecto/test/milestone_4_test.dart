import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:inspecto/domain/entities/api_request.dart';
import 'package:inspecto/domain/entities/api_response.dart';
import 'package:inspecto/data/datasources/sse_stream_data_source.dart';
import 'package:inspecto/data/datasources/websocket_data_source.dart';
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
}
