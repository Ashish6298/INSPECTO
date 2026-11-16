import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspecto/core/utils/curl_parser.dart';
import 'package:inspecto/core/utils/code_generator.dart';
import 'package:inspecto/domain/entities/api_request.dart';
import 'package:inspecto/domain/entities/api_response.dart';
import 'package:inspecto/domain/entities/history_item.dart';
import 'package:inspecto/data/datasources/history_local_data_source.dart';
import 'package:inspecto/presentation/providers/history_provider.dart';

void main() {
  group('Phase 2.0: cURL Parser Tests', () {
    test('Parses complex POST cURL with headers and JSON body', () {
      const curl = '''
curl -X POST https://api.example.com/v1/users \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer my_jwt_token" \\
  -d '{"name": "Alice", "role": "admin"}'
''';

      final request = CurlParser.parse(curl);

      expect(request.method, equals(HttpMethod.POST));
      expect(request.url, equals('https://api.example.com/v1/users'));
      expect(request.headers['Content-Type'], equals('application/json'));
      expect(request.authType, equals('bearer'));
      expect(request.authDetails?['token'], equals('my_jwt_token'));
      expect(request.body, equals('{"name": "Alice", "role": "admin"}'));
      expect(request.bodyType, equals('json'));
    });

    test('Parses GET cURL with query parameters', () {
      const curl = 'curl "https://api.example.com/search?q=flutter&page=1"';
      final request = CurlParser.parse(curl);

      expect(request.method, equals(HttpMethod.GET));
      expect(request.params['q'], equals('flutter'));
      expect(request.params['page'], equals('1'));
    });

    test('Parses Basic Auth cURL (-u user:pass)', () {
      const curl = 'curl -u "admin:secret123" https://api.example.com/admin';
      final request = CurlParser.parse(curl);

      expect(request.authType, equals('basic'));
      expect(request.authDetails?['username'], equals('admin'));
      expect(request.authDetails?['password'], equals('secret123'));
    });
  });

  group('Phase 2.0: Multi-Language Code Generator Tests', () {
    final sampleRequest = ApiRequest(
      id: 'req_1',
      method: HttpMethod.POST,
      url: 'https://api.example.com/v1/items',
      headers: {'Accept': 'application/json'},
      params: {'sort': 'asc'},
      body: '{"title":"Test Item"}',
      bodyType: 'json',
      authType: 'bearer',
      authDetails: {'token': 'xyz_token'},
    );

    test('Generates cURL code snippet', () {
      final code = CodeGenerator.generate(sampleRequest, CodeLanguage.curl);
      expect(code, contains('curl -X POST'));
      expect(code, contains('https://api.example.com/v1/items?sort=asc'));
      expect(code, contains('-H \'Authorization: Bearer xyz_token\''));
      expect(code, contains('-d \'{"title":"Test Item"}\''));
    });

    test('Generates Dart (http) code snippet', () {
      final code = CodeGenerator.generate(sampleRequest, CodeLanguage.dartHttp);
      expect(code, contains("import 'package:http/http.dart' as http;"));
      expect(code, contains("http.post("));
    });

    test('Generates JavaScript (fetch) code snippet', () {
      final code = CodeGenerator.generate(sampleRequest, CodeLanguage.jsFetch);
      expect(code, contains("fetch(url, options)"));
      expect(code, contains("method: 'POST'"));
    });

    test('Generates Python (requests) code snippet', () {
      final code =
          CodeGenerator.generate(sampleRequest, CodeLanguage.pythonRequests);
      expect(code, contains("import requests"));
      expect(code, contains("requests.post("));
    });

    test('Generates Go (net/http) code snippet', () {
      final code = CodeGenerator.generate(sampleRequest, CodeLanguage.go);
      expect(code, contains('package main'));
      expect(code, contains('http.NewRequest("POST", url, payload)'));
    });
  });

  group('Phase 2.1: Execution History Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('HistoryItem serializes and deserializes cleanly', () {
      final now = DateTime.now();
      final item = HistoryItem(
        id: 'h_1',
        timestamp: now,
        request: ApiRequest(
          id: 'req_1',
          method: HttpMethod.GET,
          url: 'https://api.example.com/test',
          headers: {},
          params: {},
        ),
        statusCode: 200,
        responseTimeMs: 145,
        responseSize: 512,
      );

      final json = item.toJson();
      final decoded = HistoryItem.fromJson(json);

      expect(decoded.id, equals('h_1'));
      expect(decoded.statusCode, equals(200));
      expect(decoded.responseTimeMs, equals(145));
      expect(decoded.request.url, equals('https://api.example.com/test'));
    });

    test('HistoryProvider adds and manages recents queue', () async {
      final dataSource = HistoryLocalDataSource();
      final provider = HistoryProvider(dataSource: dataSource);

      await provider.loadHistory();
      expect(provider.history, isEmpty);

      final req = ApiRequest(
        id: 'req_1',
        method: HttpMethod.GET,
        url: 'https://api.example.com/status',
        headers: {},
        params: {},
      );
      final res = ApiResponse(
        statusCode: 200,
        body: '{"status":"ok"}',
        headers: {},
        responseTimeMs: 98,
        responseSize: 15,
      );

      await provider.addEntry(request: req, response: res);

      expect(provider.history.length, equals(1));
      expect(provider.history.first.request.url, equals('https://api.example.com/status'));
      expect(provider.history.first.statusCode, equals(200));

      // Reload from local storage
      await provider.loadHistory();
      expect(provider.history.length, equals(1));

      // Clear history
      await provider.clearHistory();
      expect(provider.history, isEmpty);
    });
  });
}
