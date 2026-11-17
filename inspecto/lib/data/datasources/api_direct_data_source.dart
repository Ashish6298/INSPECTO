import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_request_model.dart';
import '../../domain/entities/api_response.dart';

class ApiDirectDataSource {
  final http.Client _client;

  ApiDirectDataSource({http.Client? client}) : _client = client ?? http.Client();

  /// Executes request directly from the Flutter client with real-time latency measurement
  /// and local environment variable interpolation.
  Future<ApiResponse> executeRequest(
    ApiRequestModel request, {
    Map<String, String>? environmentVariables,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      // 1. Resolve URL & Query Parameters
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
        final mergedParams = Map<String, String>.from(uri.queryParameters);
        mergedParams.addAll(resolvedParams);
        uri = uri.replace(queryParameters: mergedParams);
      }

      // 2. Resolve Headers
      final Map<String, String> resolvedHeaders = {};
      for (final entry in request.headers.entries) {
        if (entry.key.trim().isNotEmpty) {
          final k = _resolve(entry.key, environmentVariables);
          final v = _resolve(entry.value, environmentVariables);
          resolvedHeaders[k] = v;
        }
      }

      // 3. Resolve Authorization
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

        // Auto-set Content-Type if JSON and not explicitly configured
        if (request.bodyType == 'json' &&
            !resolvedHeaders.keys
                .any((k) => k.toLowerCase() == 'content-type')) {
          resolvedHeaders['Content-Type'] = 'application/json; charset=utf-8';
        }
      }

      // 5. Send Native HTTP Request
      final httpRequest = http.Request(request.method.name, uri);
      httpRequest.headers.addAll(resolvedHeaders);
      if (bodyBytes != null) {
        httpRequest.bodyBytes = bodyBytes;
      }

      final streamedResponse = await _client.send(httpRequest);
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();

      // Normalize Response Headers
      final Map<String, String> responseHeaders = {};
      response.headers.forEach((key, value) {
        responseHeaders[key] = value;
      });

      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: responseHeaders,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        responseSize: response.bodyBytes.length,
      );
    } catch (e) {
      stopwatch.stop();
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'error': e.toString()}),
        headers: {},
        responseTimeMs: stopwatch.elapsedMilliseconds,
        responseSize: 0,
      );
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
