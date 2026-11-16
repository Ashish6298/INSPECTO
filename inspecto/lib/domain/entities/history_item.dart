import 'api_request.dart';
import '../../data/models/api_request_model.dart';

class HistoryItem {
  final String id;
  final DateTime timestamp;
  final ApiRequest request;
  final int statusCode;
  final int responseTimeMs;
  final int responseSize;

  HistoryItem({
    required this.id,
    required this.timestamp,
    required this.request,
    required this.statusCode,
    required this.responseTimeMs,
    required this.responseSize,
  });

  Map<String, dynamic> toJson() {
    final model = ApiRequestModel.fromEntity(request);
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'request': model.toJson(),
      'statusCode': statusCode,
      'responseTimeMs': responseTimeMs,
      'responseSize': responseSize,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      request: ApiRequestModel.fromJson(
        Map<String, dynamic>.from(json['request'] as Map),
      ),
      statusCode: json['statusCode'] as int? ?? 0,
      responseTimeMs: json['responseTimeMs'] as int? ?? 0,
      responseSize: json['responseSize'] as int? ?? 0,
    );
  }
}
