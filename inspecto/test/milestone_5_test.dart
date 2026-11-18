import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inspecto/domain/entities/api_request.dart';
import 'package:inspecto/domain/entities/api_response.dart';
import 'package:inspecto/domain/entities/collection.dart';
import 'package:inspecto/domain/entities/environment.dart';
import 'package:inspecto/domain/entities/history_item.dart';
import 'package:inspecto/domain/entities/tab_session.dart';
import 'package:inspecto/domain/repositories/api_repository.dart';
import 'package:inspecto/domain/repositories/collection_repository.dart';
import 'package:inspecto/domain/repositories/environment_repository.dart';
import 'package:inspecto/data/datasources/history_local_data_source.dart';
import 'package:inspecto/data/datasources/websocket_data_source.dart';
import 'package:inspecto/presentation/providers/workspace_provider.dart';
import 'package:inspecto/presentation/providers/request_provider.dart';
import 'package:inspecto/presentation/providers/theme_provider.dart';
import 'package:inspecto/presentation/providers/collection_provider.dart';
import 'package:inspecto/presentation/providers/environment_provider.dart';
import 'package:inspecto/presentation/providers/history_provider.dart';
import 'package:inspecto/presentation/providers/websocket_provider.dart';
import 'package:inspecto/presentation/screens/desktop_main_screen.dart';
import 'package:inspecto/presentation/screens/main_screen.dart';
import 'package:inspecto/core/utils/keyboard_shortcuts.dart';

class DummyApiRepository implements ApiRepository {
  @override
  Future<ApiResponse> executeRequest(ApiRequest request) async {
    return ApiResponse(
      statusCode: 200,
      body: '{"success": true}',
      headers: {'content-type': 'application/json'},
      responseTimeMs: 25,
      responseSize: 19,
    );
  }
}

class DummyCollectionRepository implements CollectionRepository {
  @override
  Future<List<Collection>> getCollections() async => [];
  @override
  Future<String?> createCollection(String name) async => 'col_1';
  @override
  Future<void> saveRequestToCollection(
      String collectionId, ApiRequest request) async {}
}

class DummyEnvironmentRepository implements EnvironmentRepository {
  @override
  Future<List<Environment>> getEnvironments() async => [];
  @override
  Future<void> saveEnvironment(Environment environment) async {}
  @override
  Future<void> deleteEnvironment(String id) async {}
}

class DummyHistoryDataSource extends HistoryLocalDataSource {
  final List<HistoryItem> _items = [];

  @override
  Future<List<HistoryItem>> getHistory() async => List.from(_items);

  @override
  Future<void> saveHistoryItem(HistoryItem item) async {
    _items.insert(0, item);
  }

  @override
  Future<void> clearHistory() async {
    _items.clear();
  }
}

void main() {
  group('Phase 5.0: Multi-Tab Request Workspace Tests', () {
    test('TabSession creates initial instance and handles copyWith', () {
      final tab = TabSession.initial(title: 'My Request');

      expect(tab.title, equals('My Request'));
      expect(tab.displayTitle, equals('My Request'));
      expect(tab.isDirty, isFalse);
      expect(tab.request.method, equals(HttpMethod.GET));

      // Dirty display
      final dirtyTab = tab.copyWith(isDirty: true);
      expect(dirtyTab.displayTitle, equals('My Request *'));
      expect(dirtyTab.isDirty, isTrue);

      // Response association
      final res = ApiResponse(
        statusCode: 201,
        body: '{"id": 1}',
        headers: {},
        responseTimeMs: 30,
        responseSize: 10,
      );
      final tabWithRes = dirtyTab.copyWith(response: res);
      expect(tabWithRes.response?.statusCode, equals(201));
    });

    test('WorkspaceProvider manages tab lifecycle: new, switch, duplicate, close', () {
      final ws = WorkspaceProvider();
      final reqProvider = RequestProvider(apiRepository: DummyApiRepository());

      // 1. Initial State
      expect(ws.tabCount, equals(1));
      expect(ws.activeTabIndex, equals(0));
      expect(ws.activeTab.title, equals('Untitled Request'));

      // 2. Edit Tab 0 in RequestProvider
      reqProvider.setUrl('https://api.example.com/users');
      reqProvider.setMethod(HttpMethod.POST);
      reqProvider.setBody('{"name": "Alice"}');

      // 3. Create Tab 1
      ws.newTab(
        request: ApiRequest(
          id: 'req_tab1',
          method: HttpMethod.GET,
          url: 'https://api.example.com/posts',
          headers: {},
          params: {},
        ),
        title: 'Get Posts',
        requestProvider: reqProvider,
      );

      expect(ws.tabCount, equals(2));
      expect(ws.activeTabIndex, equals(1));
      expect(ws.activeTab.title, equals('Get Posts'));
      // RequestProvider now has Tab 1's state
      expect(reqProvider.url, equals('https://api.example.com/posts'));

      // 4. Switch back to Tab 0
      ws.switchTab(0, requestProvider: reqProvider);
      expect(ws.activeTabIndex, equals(0));
      // Tab 0 state was preserved and restored into RequestProvider!
      expect(reqProvider.url, equals('https://api.example.com/users'));
      expect(reqProvider.method, equals(HttpMethod.POST));
      expect(reqProvider.body, equals('{"name": "Alice"}'));

      // 5. Duplicate Tab 0
      ws.duplicateTab(0, requestProvider: reqProvider);
      expect(ws.tabCount, equals(3));
      expect(ws.activeTabIndex, equals(1));
      expect(ws.activeTab.title, contains('(Copy)'));
      expect(ws.activeTab.isDirty, isTrue);

      // 6. Close Tab
      ws.closeTab(1, requestProvider: reqProvider);
      expect(ws.tabCount, equals(2));

      // 7. Close Other Tabs
      ws.closeOtherTabs(0, requestProvider: reqProvider);
      expect(ws.tabCount, equals(1));
    });

    test('WorkspaceProvider openRequest loads into pristine tab or opens new tab', () {
      final ws = WorkspaceProvider();
      final reqProvider = RequestProvider(apiRepository: DummyApiRepository());

      final req1 = ApiRequest(
        id: 'req1',
        method: HttpMethod.GET,
        url: 'https://api.example.com/first',
        headers: {},
        params: {},
      );

      // Pristine active tab should be reused
      ws.openRequest(req1, requestProvider: reqProvider);
      expect(ws.tabCount, equals(1));
      expect(ws.activeTab.url, equals('https://api.example.com/first'));

      // Now active tab is not empty, opening second request opens a new tab
      final req2 = ApiRequest(
        id: 'req2',
        method: HttpMethod.DELETE,
        url: 'https://api.example.com/second',
        headers: {},
        params: {},
      );
      ws.openRequest(req2, requestProvider: reqProvider);
      expect(ws.tabCount, equals(2));
      expect(ws.activeTabIndex, equals(1));
      expect(ws.activeTab.url, equals('https://api.example.com/second'));
    });
  });

  group('Phase 5.1: Desktop Responsive Multi-Pane & Shortcuts Tests', () {
    test('AppKeyboardShortcuts constants match specifications', () {
      // Ctrl/Cmd + Enter
      expect(AppKeyboardShortcuts.sendRequestCtrl.control, isTrue);
      expect(AppKeyboardShortcuts.sendRequestMeta.meta, isTrue);

      // Ctrl/Cmd + S
      expect(AppKeyboardShortcuts.saveRequestCtrl.control, isTrue);
      expect(AppKeyboardShortcuts.saveRequestMeta.meta, isTrue);

      // Ctrl/Cmd + T
      expect(AppKeyboardShortcuts.newTabCtrl.control, isTrue);
      expect(AppKeyboardShortcuts.newTabMeta.meta, isTrue);

      // Ctrl/Cmd + W
      expect(AppKeyboardShortcuts.closeTabCtrl.control, isTrue);
      expect(AppKeyboardShortcuts.closeTabMeta.meta, isTrue);

      // Ctrl/Cmd + /
      expect(AppKeyboardShortcuts.focusUrlCtrl.control, isTrue);
      expect(AppKeyboardShortcuts.focusUrlMeta.meta, isTrue);
    });

    testWidgets('MainScreen adapts to DesktopMainScreen when width > 900',
        (tester) async {
      // Set desktop screen size (1200x800)
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(
              create: (_) =>
                  RequestProvider(apiRepository: DummyApiRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  CollectionProvider(repository: DummyCollectionRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) => EnvironmentProvider(
                  repository: DummyEnvironmentRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  HistoryProvider(dataSource: DummyHistoryDataSource()),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  WebSocketProvider(dataSource: WebSocketDataSource()),
            ),
            ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
          ],
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On width > 900, DesktopMainScreen should be rendered!
      expect(find.byType(DesktopMainScreen), findsOneWidget);
      expect(find.text('WORKSTATION'), findsOneWidget);
      expect(find.text('RESPONSE'), findsOneWidget);
    });

    testWidgets('MainScreen renders mobile NavigationBar when width <= 900',
        (tester) async {
      // Set mobile screen size (600x800)
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(
              create: (_) =>
                  RequestProvider(apiRepository: DummyApiRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  CollectionProvider(repository: DummyCollectionRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) => EnvironmentProvider(
                  repository: DummyEnvironmentRepository()),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  HistoryProvider(dataSource: DummyHistoryDataSource()),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  WebSocketProvider(dataSource: WebSocketDataSource()),
            ),
            ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
          ],
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On width <= 900, DesktopMainScreen should NOT be rendered; mobile NavigationBar is present
      expect(find.byType(DesktopMainScreen), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
