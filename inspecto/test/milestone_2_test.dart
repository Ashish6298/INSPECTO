import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspecto/core/utils/curl_parser.dart';
import 'package:inspecto/core/utils/code_generator.dart';
import 'package:inspecto/domain/entities/api_request.dart';
import 'package:inspecto/domain/entities/api_response.dart';
import 'package:inspecto/domain/entities/history_item.dart';
import 'package:inspecto/data/datasources/history_local_data_source.dart';
import 'package:inspecto/presentation/providers/history_provider.dart';
import 'package:inspecto/presentation/widgets/response_headers_view.dart';
import 'package:inspecto/presentation/widgets/response_cookies_view.dart';

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

  group('Phase 2.2: Advanced Response Viewer Tests', () {
    test('ParsedCookie parses single and multiple cookies correctly', () {
      final headers = {
        'content-type': 'application/json',
        'set-cookie':
            'sessionId=abc12345; Path=/; Domain=example.com; HttpOnly; Secure; SameSite=Strict, theme=dark; Max-Age=3600; Path=/',
      };

      final cookies = ParsedCookie.parseHeaders(headers);
      expect(cookies.length, equals(2));

      final c1 = cookies[0];
      expect(c1.name, equals('sessionId'));
      expect(c1.value, equals('abc12345'));
      expect(c1.path, equals('/'));
      expect(c1.domain, equals('example.com'));
      expect(c1.httpOnly, isTrue);
      expect(c1.secure, isTrue);
      expect(c1.sameSite, equals('Strict'));

      final c2 = cookies[1];
      expect(c2.name, equals('theme'));
      expect(c2.value, equals('dark'));
      expect(c2.expires, contains('3600'));
      expect(c2.httpOnly, isFalse);
    });

    test('ParsedCookie handles Expires header with embedded comma', () {
      final headers = {
        'set-cookie':
            'id=a3fWa; Expires=Wed, 21 Oct 2026 07:28:00 GMT; Path=/; Secure, token=xyz789; HttpOnly',
      };

      final cookies = ParsedCookie.parseHeaders(headers);
      expect(cookies.length, equals(2));
      expect(cookies[0].name, equals('id'));
      expect(cookies[0].expires, contains('Wed, 21 Oct 2026'));
      expect(cookies[1].name, equals('token'));
      expect(cookies[1].httpOnly, isTrue);
    });

    test('ParsedCookie returns empty list when no set-cookie header exists', () {
      final cookies = ParsedCookie.parseHeaders({'content-type': 'text/plain'});
      expect(cookies, isEmpty);
    });

    testWidgets('ResponseHeadersView renders headers table and filters by query',
        (WidgetTester tester) async {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer sample_token',
        'X-Trace-Id': 'trace-999',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResponseHeadersView(headers: headers),
            ),
          ),
        ),
      );

      expect(find.text('Content-Type'), findsOneWidget);
      expect(find.text('application/json'), findsOneWidget);
      expect(find.text('X-Trace-Id'), findsOneWidget);

      // Search for 'trace'
      await tester.enterText(find.byType(TextField), 'trace');
      await tester.pump();

      expect(find.text('X-Trace-Id'), findsOneWidget);
      expect(find.text('Content-Type'), findsNothing);
    });

    testWidgets('ResponseCookiesView renders cookies with flags',
        (WidgetTester tester) async {
      final headers = {
        'set-cookie': 'auth_token=jwt_val; Path=/api; HttpOnly; Secure',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResponseCookiesView(headers: headers),
            ),
          ),
        ),
      );

      expect(find.text('auth_token'), findsOneWidget);
      expect(find.text('jwt_val'), findsOneWidget);
      expect(find.text('HttpOnly'), findsOneWidget);
      expect(find.text('Secure'), findsOneWidget);
    });
  });
}
