import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_request_model.dart';
import '../../domain/entities/api_response.dart';

class ApiRemoteDataSource {
  final String baseUrl = 'http://10.0.2.2:5000/api';

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
