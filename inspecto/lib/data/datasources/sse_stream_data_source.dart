import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/api_request.dart';

class SseEvent {
  final String? id;
  final String? event;
  final String data;
  final bool isDone;
  final String raw;

  SseEvent({
    this.id,
    this.event,
    required this.data,
    this.isDone = false,
    this.raw = '',
  });

  @override
  String toString() =>
      'SseEvent(id: $id, event: $event, data: $data, isDone: $isDone)';
}

class SseStreamDataSource {
  final http.Client _client;

  SseStreamDataSource({http.Client? client})
      : _client = client ?? http.Client();

  /// Streams real-time Server-Sent Events (SSE) from the target endpoint.
  Stream<SseEvent> streamRequest(
    ApiRequest request, {
    Map<String, String>? environmentVariables,
  }) async* {
    // 1. Resolve Variables
    final resolvedUrl = _resolve(request.url, environmentVariables);
    Uri uri = Uri.parse(resolvedUrl);

    final Map<String, String> resolvedParams = {};
    for (final entry in request.params.entries) {
      if (entry.key.trim().isNotEmpty) {
        final k = _resolve(entry.key, environmentVariables);
        final v = _resolve(entry.value, environmentVariables);
        resolvedParams[k] = v;
      }
    }

    if (resolvedParams.isNotEmpty) {
      final merged = Map<String, String>.from(uri.queryParameters);
      merged.addAll(resolvedParams);
      uri = uri.replace(queryParameters: merged);
    }

    // 2. Resolve Headers
    final Map<String, String> resolvedHeaders = {
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    };

    for (final entry in request.headers.entries) {
      if (entry.key.trim().isNotEmpty) {
        final k = _resolve(entry.key, environmentVariables);
        final v = _resolve(entry.value, environmentVariables);
        resolvedHeaders[k] = v;
      }
    }

    // 3. Resolve Auth
    final authType = request.authType?.toLowerCase() ?? 'none';
    if (authType == 'bearer') {
      final rawToken = request.authDetails?['token']?.toString() ?? '';
      final token = _resolve(rawToken, environmentVariables);
      if (token.isNotEmpty) {
        resolvedHeaders['Authorization'] = 'Bearer $token';
      }
    } else if (authType == 'basic') {
      final rawUser = request.authDetails?['username']?.toString() ?? '';
      final rawPass = request.authDetails?['password']?.toString() ?? '';
      final user = _resolve(rawUser, environmentVariables);
      final pass = _resolve(rawPass, environmentVariables);
      final credentials = base64Encode(utf8.encode('$user:$pass'));
      resolvedHeaders['Authorization'] = 'Basic $credentials';
    } else if (authType == 'apikey') {
      final rawKey = request.authDetails?['key']?.toString() ?? '';
      final rawVal = request.authDetails?['value']?.toString() ?? '';
      final key = _resolve(rawKey, environmentVariables);
      final val = _resolve(rawVal, environmentVariables);
      if (key.isNotEmpty) {
        resolvedHeaders[key] = val;
      }
    }

    // 4. Resolve Body Payload
    List<int>? bodyBytes;
    if (request.body != null && request.body!.isNotEmpty) {
      final resolvedBody = _resolve(request.body!, environmentVariables);
      bodyBytes = utf8.encode(resolvedBody);

      if (request.bodyType == 'json' &&
          !resolvedHeaders.keys.any((k) => k.toLowerCase() == 'content-type')) {
        resolvedHeaders['Content-Type'] = 'application/json; charset=utf-8';
      }
    }

    // 5. Build and Send Streamed HTTP Request
    final httpRequest = http.Request(request.method.name, uri);
    httpRequest.headers.addAll(resolvedHeaders);
    if (bodyBytes != null) {
      httpRequest.bodyBytes = bodyBytes;
    }

    final streamedResponse = await _client.send(httpRequest);

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw http.ClientException(
        'Server returned HTTP ${streamedResponse.statusCode}: $errorBody',
        uri,
      );
    }

    // 6. Decode Chunks into SSE Events
    String? currentId;
    String? currentEvent;
    final List<String> currentDataLines = [];

    final linesStream = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in linesStream) {
      final trimmed = line.trim();

      // Empty line indicates event boundary in SSE specification
      if (trimmed.isEmpty) {
        if (currentDataLines.isNotEmpty) {
          final joinedData = currentDataLines.join('\n');
          final isDone = joinedData == '[DONE]';
          yield SseEvent(
            id: currentId,
            event: currentEvent,
            data: joinedData,
            isDone: isDone,
            raw: line,
          );
          currentDataLines.clear();
          currentEvent = null;
        }
        continue;
      }

      // Comment / Keep-alive line
      if (trimmed.startsWith(':')) {
        continue;
      }

      if (trimmed.startsWith('data:')) {
        final dataPart = trimmed.substring(5).trim();
        if (dataPart == '[DONE]') {
          yield SseEvent(
            id: currentId,
            event: currentEvent,
            data: '[DONE]',
            isDone: true,
            raw: line,
          );
          currentDataLines.clear();
          return;
        }
        currentDataLines.add(dataPart);
      } else if (trimmed.startsWith('event:')) {
        currentEvent = trimmed.substring(6).trim();
      } else if (trimmed.startsWith('id:')) {
        currentId = trimmed.substring(3).trim();
      } else {
        // Fallback: raw line chunk without prefix
        currentDataLines.add(trimmed);
      }
    }

    // Emit any remaining pending buffer
    if (currentDataLines.isNotEmpty) {
      final joinedData = currentDataLines.join('\n');
      yield SseEvent(
        id: currentId,
        event: currentEvent,
        data: joinedData,
        isDone: joinedData == '[DONE]',
      );
    }
  }

  /// Extracts textual delta from AI completions chunk (OpenAI, Ollama, Gemini, Claude)
  static String extractLlmDelta(String data) {
    if (data.trim() == '[DONE]') return '';
    try {
      final dynamic decoded = jsonDecode(data);
      if (decoded is! Map) return data;

      // 1. OpenAI / Ollama style: choices[0].delta.content or choices[0].text
      if (decoded['choices'] is List && (decoded['choices'] as List).isNotEmpty) {
        final firstChoice = (decoded['choices'] as List).first;
        if (firstChoice is Map) {
          if (firstChoice['delta'] is Map &&
              firstChoice['delta']['content'] != null) {
            return firstChoice['delta']['content'].toString();
          }
          if (firstChoice['text'] != null) {
            return firstChoice['text'].toString();
          }
        }
      }

      // 2. Ollama / vLLM style: response
      if (decoded['response'] != null) {
        return decoded['response'].toString();
      }

      // 3. Google Gemini style: candidates[0].content.parts[0].text
      if (decoded['candidates'] is List &&
          (decoded['candidates'] as List).isNotEmpty) {
        final firstCandidate = (decoded['candidates'] as List).first;
        if (firstCandidate is Map && firstCandidate['content'] is Map) {
          final parts = firstCandidate['content']['parts'];
          if (parts is List && parts.isNotEmpty && parts.first is Map) {
            return parts.first['text']?.toString() ?? '';
          }
        }
      }

      // 4. Anthropic style: delta.text
      if (decoded['delta'] is Map && decoded['delta']['text'] != null) {
        return decoded['delta']['text'].toString();
      }

      // Fallback: if message is present
      if (decoded['message'] != null) {
        return decoded['message'].toString();
      }

      return data;
    } catch (_) {
      return data;
    }
  }

  static String _resolve(String text, Map<String, String>? vars) {
    if (vars == null || vars.isEmpty || text.isEmpty) return text;
    String result = text;
    for (final entry in vars.entries) {
      final pattern = RegExp('\\{\\{${RegExp.escape(entry.key)}\\}\\}');
      result = result.replaceAll(pattern, entry.value);
    }
    return result;
  }
}
