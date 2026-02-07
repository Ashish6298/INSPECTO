class ApiResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;
  final int responseTimeMs;
  final int responseSize;

  ApiResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
    required this.responseTimeMs,
    required this.responseSize,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isError => statusCode >= 400;

  String get sizeFormatted {
    if (responseSize < 1024) return '$responseSize B';
    if (responseSize < 1024 * 1024)
      return '${(responseSize / 1024).toStringAsFixed(1)} KB';
    return '${(responseSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
