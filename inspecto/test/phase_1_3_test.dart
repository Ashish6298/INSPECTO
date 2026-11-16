import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inspecto/domain/entities/api_request.dart';
import 'package:inspecto/presentation/providers/request_provider.dart';
import 'package:inspecto/presentation/widgets/key_value_list.dart';
import 'package:inspecto/presentation/widgets/request_tabs.dart';
import 'package:inspecto/data/repositories/api_repository_impl.dart';
import 'package:inspecto/data/datasources/api_remote_data_source.dart';

void main() {
  group('Phase 1.3: Connecting Workflows & Controller Lifecycle Tests', () {
    test('RequestProvider loadRequest populates all fields accurately', () {
      final repo = ApiRepositoryImpl(remoteDataSource: ApiRemoteDataSource());
      final provider = RequestProvider(apiRepository: repo);

      final sampleRequest = ApiRequest(
        id: 'req_123',
        method: HttpMethod.POST,
        url: 'https://api.example.com/v1/auth',
        headers: {'Content-Type': 'application/json', 'X-App': 'Inspecto'},
        params: {'version': '2'},
        body: '{"username":"admin"}',
        bodyType: 'json',
        bodySubType: 'json',
        authType: 'bearer',
        authDetails: {'token': 'my_token'},
      );

      provider.loadRequest(sampleRequest);

      expect(provider.method, equals(HttpMethod.POST));
      expect(provider.url, equals('https://api.example.com/v1/auth'));
      expect(provider.headers['Content-Type'], equals('application/json'));
      expect(provider.headers['X-App'], equals('Inspecto'));
      expect(provider.params['version'], equals('2'));
      expect(provider.body, equals('{"username":"admin"}'));
      expect(provider.bodyType, equals('json'));
      expect(provider.authType, equals('bearer'));
      expect(provider.authDetails['token'], equals('my_token'));

      final extracted = provider.getCurrentRequest();
      expect(extracted.url, equals('https://api.example.com/v1/auth'));
      expect(extracted.method, equals(HttpMethod.POST));
    });

    testWidgets('KeyValueList initializes, edits, adds, and removes rows cleanly',
        (WidgetTester tester) async {
      Map<String, String> currentData = {'key1': 'val1'};
      Map<String, String>? lastUpdated;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeyValueList(
              title: 'Headers',
              data: currentData,
              onChanged: (data) => lastUpdated = data,
            ),
          ),
        ),
      );

      // Verify row 1 is rendered
      expect(find.text('key1'), findsOneWidget);
      expect(find.text('val1'), findsOneWidget);

      // Tap Add Row button
      await tester.tap(find.text('Add Row'));
      await tester.pumpAndSettle();

      // Enter text into the new key field
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(4)); // 2 rows * 2 fields

      // Enter value in second row
      await tester.enterText(textFields.at(2), 'key2');
      await tester.enterText(textFields.at(3), 'val2');
      await tester.pumpAndSettle();

      expect(lastUpdated, isNotNull);
      expect(lastUpdated!['key2'], equals('val2'));

      // Remove row 1
      final deleteButtons = find.byIcon(Icons.close_rounded);
      expect(deleteButtons, findsNWidgets(2));
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      expect(lastUpdated!.containsKey('key1'), isFalse);
      expect(lastUpdated!['key2'], equals('val2'));
    });

    testWidgets('RequestTabs initializes and disposes TabController without leaks',
        (WidgetTester tester) async {
      final repo = ApiRepositoryImpl(remoteDataSource: ApiRemoteDataSource());
      final provider = RequestProvider(apiRepository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<RequestProvider>.value(
              value: provider,
              child: const RequestTabs(),
            ),
          ),
        ),
      );

      expect(find.text('Params'), findsOneWidget);
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Headers'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);

      // Dispose widget tree to verify TabController disposal does not throw
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
