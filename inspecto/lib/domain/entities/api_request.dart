enum HttpMethod { GET, POST, PUT, DELETE, PATCH }

class ApiRequest {
  final String id;
  final HttpMethod method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> params;
  final String? body;
  final String? bodyType; // 'none', 'json', 'form'

  ApiRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.headers,
    required this.params,
    this.body,
    this.bodyType = 'none',
  });
}
