import 'package:flutter/material.dart';
import '../../domain/entities/api_request.dart';
import '../../domain/entities/api_response.dart';
import '../../domain/entities/tab_session.dart';
import 'request_provider.dart';

class WorkspaceProvider extends ChangeNotifier {
  late List<TabSession> _tabs;
  int _activeTabIndex = 0;

  WorkspaceProvider() {
    _tabs = [
      TabSession.initial(
        id: 'tab_init_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Untitled Request',
      ),
    ];
    _activeTabIndex = 0;
  }

  /// List of open tabs in the workspace
  List<TabSession> get tabs => List.unmodifiable(_tabs);

  /// Current active tab index
  int get activeTabIndex => _activeTabIndex;

  /// Total count of open tabs
  int get tabCount => _tabs.length;

  /// Currently active tab session
  TabSession get activeTab {
    if (_tabs.isEmpty) {
      _tabs.add(TabSession.initial());
      _activeTabIndex = 0;
    }
    if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    }
    return _tabs[_activeTabIndex];
  }

  /// Helper to save current RequestProvider state into active tab session
  void _saveCurrentToActiveTab(RequestProvider requestProvider) {
    if (_tabs.isEmpty || _activeTabIndex >= _tabs.length) return;
    final currentReq = requestProvider.getCurrentRequest();
    final active = _tabs[_activeTabIndex];

    // Determine title
    String newTitle = active.title;
    if (active.title == 'Untitled Request' && currentReq.url.isNotEmpty) {
      newTitle = _deriveTitle(currentReq);
    }

    _tabs[_activeTabIndex] = active.copyWith(
      request: currentReq,
      response: requestProvider.response,
      title: newTitle,
    );
  }

  static String _deriveTitle(ApiRequest request) {
    if (request.url.trim().isEmpty) return 'Untitled Request';
    try {
      final uri = Uri.parse(request.url);
      final path = uri.path.trim();
      if (path.isNotEmpty && path != '/') {
        return '${request.method.name} $path';
      }
      return '${request.method.name} ${uri.host}';
    } catch (_) {
      final clean = request.url.replaceAll(RegExp(r'^https?://'), '');
      return '${request.method.name} $clean';
    }
  }

  /// Creates a new tab session and makes it active
  void newTab({
    ApiRequest? request,
    String? title,
    RequestProvider? requestProvider,
  }) {
    if (requestProvider != null && _tabs.isNotEmpty) {
      _saveCurrentToActiveTab(requestProvider);
    }

    final newReq = request ??
        ApiRequest(
          id: 'req_${DateTime.now().millisecondsSinceEpoch}',
          method: HttpMethod.GET,
          url: '',
          headers: {},
          params: {},
        );

    final resolvedTitle =
        title ?? (newReq.url.isNotEmpty ? _deriveTitle(newReq) : 'Untitled Request');

    final newSession = TabSession(
      id: 'tab_${DateTime.now().millisecondsSinceEpoch}_${_tabs.length}',
      title: resolvedTitle,
      request: newReq,
      response: null,
      isDirty: false,
    );

    _tabs.add(newSession);
    _activeTabIndex = _tabs.length - 1;

    if (requestProvider != null) {
      requestProvider.loadRequestWithResponse(newSession.request, null);
    }
    notifyListeners();
  }

  /// Closes the tab at [index]. If only 1 tab remains, resets it to clean state.
  void closeTab(int index, {RequestProvider? requestProvider}) {
    if (index < 0 || index >= _tabs.length) return;

    if (_tabs.length <= 1) {
      // Don't leave zero tabs; reset active tab
      final fresh = TabSession.initial();
      _tabs = [fresh];
      _activeTabIndex = 0;
      if (requestProvider != null) {
        requestProvider.loadRequestWithResponse(fresh.request, null);
      }
      notifyListeners();
      return;
    }

    if (index == _activeTabIndex) {
      _tabs.removeAt(index);
      if (_activeTabIndex >= _tabs.length) {
        _activeTabIndex = _tabs.length - 1;
      }
      if (requestProvider != null) {
        requestProvider.loadRequestWithResponse(
          _tabs[_activeTabIndex].request,
          _tabs[_activeTabIndex].response,
        );
      }
    } else if (index < _activeTabIndex) {
      _tabs.removeAt(index);
      _activeTabIndex--;
    } else {
      _tabs.removeAt(index);
    }

    notifyListeners();
  }

  /// Closes all tabs except the tab at [index]
  void closeOtherTabs(int index, {RequestProvider? requestProvider}) {
    if (index < 0 || index >= _tabs.length) return;
    final keepTab = _tabs[index];
    _tabs = [keepTab];
    _activeTabIndex = 0;
    if (requestProvider != null) {
      requestProvider.loadRequestWithResponse(keepTab.request, keepTab.response);
    }
    notifyListeners();
  }

  /// Duplicates the tab at [index]
  void duplicateTab(int index, {RequestProvider? requestProvider}) {
    if (index < 0 || index >= _tabs.length) return;

    if (requestProvider != null) {
      _saveCurrentToActiveTab(requestProvider);
    }

    final source = _tabs[index];
    final copy = TabSession(
      id: 'tab_${DateTime.now().millisecondsSinceEpoch}_dup',
      title: '${source.title} (Copy)',
      request: ApiRequest(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        method: source.request.method,
        url: source.request.url,
        headers: Map<String, String>.from(source.request.headers),
        params: Map<String, String>.from(source.request.params),
        body: source.request.body,
        bodyType: source.request.bodyType,
        bodySubType: source.request.bodySubType,
        authType: source.request.authType,
        authDetails: Map<String, dynamic>.from(source.request.authDetails ?? {}),
        extractors: List.from(source.request.extractors ?? []),
      ),
      response: source.response,
      isDirty: true,
    );

    final insertIndex = index + 1;
    _tabs.insert(insertIndex, copy);
    _activeTabIndex = insertIndex;

    if (requestProvider != null) {
      requestProvider.loadRequestWithResponse(copy.request, copy.response);
    }
    notifyListeners();
  }

  /// Switches active tab to [index]
  void switchTab(int index, {RequestProvider? requestProvider}) {
    if (index == _activeTabIndex || index < 0 || index >= _tabs.length) return;

    if (requestProvider != null) {
      _saveCurrentToActiveTab(requestProvider);
    }

    _activeTabIndex = index;

    if (requestProvider != null) {
      final target = _tabs[index];
      requestProvider.loadRequestWithResponse(target.request, target.response);
    }
    notifyListeners();
  }

  /// Opens a request: if current active tab is pristine, loads into it;
  /// otherwise opens in a new tab.
  void openRequest(
    ApiRequest request, {
    String? title,
    RequestProvider? requestProvider,
  }) {
    final active = activeTab;
    final isPristine = !active.isDirty &&
        active.request.url.trim().isEmpty &&
        active.response == null;

    final resolvedTitle =
        title ?? (request.url.isNotEmpty ? _deriveTitle(request) : 'Saved Request');

    if (isPristine) {
      _tabs[_activeTabIndex] = active.copyWith(
        title: resolvedTitle,
        request: request,
        response: null,
        isDirty: false,
      );
      if (requestProvider != null) {
        requestProvider.loadRequestWithResponse(request, null);
      }
      notifyListeners();
    } else {
      newTab(
        request: request,
        title: resolvedTitle,
        requestProvider: requestProvider,
      );
    }
  }

  /// Syncs edits from RequestProvider into the active tab and marks dirty
  void updateActiveRequest(
    ApiRequest request, {
    bool markDirty = true,
    String? newTitle,
  }) {
    if (_tabs.isEmpty || _activeTabIndex >= _tabs.length) return;
    final active = _tabs[_activeTabIndex];

    String title = newTitle ?? active.title;
    if (active.title == 'Untitled Request' && request.url.isNotEmpty) {
      title = _deriveTitle(request);
    }

    _tabs[_activeTabIndex] = active.copyWith(
      request: request,
      title: title,
      isDirty: markDirty,
    );
    notifyListeners();
  }

  /// Updates active tab response (e.g. after execution)
  void updateActiveResponse(ApiResponse? response) {
    if (_tabs.isEmpty || _activeTabIndex >= _tabs.length) return;
    _tabs[_activeTabIndex] = _tabs[_activeTabIndex].copyWith(
      response: response,
    );
    notifyListeners();
  }

  /// Marks active tab as saved
  void markActiveSaved({String? newTitle}) {
    if (_tabs.isEmpty || _activeTabIndex >= _tabs.length) return;
    final active = _tabs[_activeTabIndex];
    _tabs[_activeTabIndex] = active.copyWith(
      title: newTitle ?? active.title,
      isDirty: false,
    );
    notifyListeners();
  }
}
