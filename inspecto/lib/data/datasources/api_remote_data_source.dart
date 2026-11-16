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

      // The backend returns the execution result, which contains status, data (body), and headers
      return ApiResponse(
        statusCode: data['status'] ?? 500,
        body: jsonEncode(data['data']),
        headers: Map<String, String>.from(data['headers'] ?? {}),
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
