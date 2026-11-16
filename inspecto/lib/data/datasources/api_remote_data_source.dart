import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/api_request_model.dart';
import '../../domain/entities/api_response.dart';

class ApiRemoteDataSource {
  final String baseUrl = ApiConfig.baseUrl;

  Future<ApiResponse> executeRequest(
      ApiRequestModel request, String? environmentId) async {
    final startTime = DateTime.now();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'request': request.toJson(),
          'environmentId': environmentId,
        }),
      );
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      final data = jsonDecode(response.body);

      // Handle backend errors (e.g., error: true)
      if (data is Map && data['error'] == true) {
        return ApiResponse(
          statusCode: 500,
          body: jsonEncode({'message': data['message'] ?? 'Unknown Error'}),
          headers: {},
          responseTimeMs: duration,
          responseSize: response.bodyBytes.length,
        );
      }

      // Safe header parsing: join multi-value list headers (e.g., set-cookie) with comma
      final Map<String, String> headers = {};
      if (data is Map && data['headers'] is Map) {
        (data['headers'] as Map).forEach((k, v) {
          headers[k.toString()] = v is List ? v.join(', ') : v.toString();
        });
      }

      // Safe body normalization
      String bodyStr = '';
      if (data is Map && data['data'] != null) {
        bodyStr = data['data'] is String
            ? data['data'] as String
            : jsonEncode(data['data']);
      }

      return ApiResponse(
        statusCode: data is Map ? (data['status'] ?? 500) : 500,
        body: bodyStr,
        headers: headers,
        responseTimeMs: duration,
        responseSize: response.bodyBytes.length,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'error': e.toString()}),
        headers: {},
        responseTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        responseSize: 0,
      );
    }
  }
}
