import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/keyboard_shortcuts.dart';
import '../providers/theme_provider.dart';
import '../providers/request_provider.dart';
import '../providers/history_provider.dart';
import '../providers/environment_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/request_url_bar.dart';
import '../widgets/request_tabs.dart';
import '../widgets/response_viewer.dart';
import '../widgets/streaming_response_viewer.dart';
import '../widgets/workspace_tab_bar.dart';
import '../widgets/curl_import_dialog.dart';
import '../widgets/code_snippet_dialog.dart';
import 'collections_screen.dart';
import 'history_screen.dart';
import 'environments_screen.dart';
import 'websocket_screen.dart';
import 'request_screen.dart';

class DesktopMainScreen extends StatefulWidget {
  const DesktopMainScreen({super.key});

  @override
  State<DesktopMainScreen> createState() => _DesktopMainScreenState();
}

class _DesktopMainScreenState extends State<DesktopMainScreen> {
  final FocusNode _urlFocusNode = FocusNode();

  // Layout sizing
  double _sidebarWidth = 280.0;
  double _centerRatio = 0.50; // Ratio of Center to (Center + Right)
  int _sidebarIndex = 0; // 0: Collections, 1: History, 2: Environments, 3: WebSocket
  bool _isSidebarCollapsed = false;

  @override
  void dispose() {
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _sendRequest() {
    final reqProvider = context.read<RequestProvider>();
    final envProvider = context.read<EnvironmentProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final wsProvider = context.read<WorkspaceProvider>();

    reqProvider.sendRequest(
      environmentProvider: envProvider,
      onResponseReceived: (req, res) {
        historyProvider.addEntry(request: req, response: res);
        wsProvider.updateActiveResponse(res);
      },
    );
  }

  void _saveRequest() {
    RequestScreen.showSaveRequestDialog(context);
  }

  void _newTab() {
    final ws = context.read<WorkspaceProvider>();
    final req = context.read<RequestProvider>();
    ws.newTab(requestProvider: req);
  }

  void _closeActiveTab() {
    final ws = context.read<WorkspaceProvider>();
    final req = context.read<RequestProvider>();
    ws.closeTab(ws.activeTabIndex, requestProvider: req);
  }

  void _focusUrl() {
    _urlFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final envProvider = context.watch<EnvironmentProvider>();
    final theme = Theme.of(context);

    return GlobalKeyboardShortcutsHandler(
      onSendRequest: _sendRequest,
      onSaveRequest: _saveRequest,
      onNewTab: _newTab,
      onCloseTab: _closeActiveTab,
      onFocusUrl: _focusUrl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          titleSpacing: 16,
          title: Row(
            children: [
              Image.asset('assets/logo.png', height: 26, width: 26),
              const SizedBox(width: 10),
              const Text(
                'INSPECTO',
                style: TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'WORKSTATION',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Active Environment Indicator
            if (envProvider.activeEnvironment != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBA6F7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFCBA6F7).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language,
                          size: 13, color: Color(0xFFCBA6F7)),
                      const SizedBox(width: 4),
                      Text(
                        envProvider.activeEnvironment!.name,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFCBA6F7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              tooltip: 'New Tab (Ctrl+T)',
              onPressed: _newTab,
            ),
            IconButton(
              icon: const Icon(Icons.terminal_rounded, size: 19),
              tooltip: 'Import cURL',
              onPressed: () => CurlImportDialog.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.code_rounded, size: 19),
              tooltip: 'Generate Code',
              onPressed: () {
                final req = requestProvider.getCurrentRequest();
                CodeSnippetDialog.show(context, req);
              },
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded, size: 19),
              tooltip: 'Save Request (Ctrl+S)',
              onPressed: _saveRequest,
            ),
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                size: 19,
              ),
              tooltip: 'Toggle Theme',
              onPressed: () => themeProvider.toggleTheme(),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final remainingWidth = availableWidth -
                (_isSidebarCollapsed ? 48.0 : _sidebarWidth) -
                12.0; // 12 for dividers
            final centerWidth = (remainingWidth * _centerRatio).clamp(320.0, remainingWidth - 320.0);
            final rightWidth = remainingWidth - centerWidth;

            return Row(
              children: [
                // 1. Left Sidebar (Collapsible & Resizable)
                if (!_isSidebarCollapsed)
                  SizedBox(
                    width: _sidebarWidth,
                    child: _buildSidebar(context),
                  )
                else
                  _buildCollapsedSidebar(context),

                // Resizable Divider 1 (Sidebar handle)
                _buildResizeHandle(
                  onDrag: (dx) {
                    setState(() {
                      _sidebarWidth =
                          (_sidebarWidth + dx).clamp(220.0, 450.0);
                    });
                  },
                ),

                // 2. Center Pane: Request Workspace
                SizedBox(
                  width: centerWidth,
                  child: _buildCenterPane(context, requestProvider),
                ),

                // Resizable Divider 2 (Center vs Right handle)
                _buildResizeHandle(
                  onDrag: (dx) {
                    setState(() {
                      final newRatio =
                          _centerRatio + (dx / remainingWidth);
                      _centerRatio = newRatio.clamp(0.25, 0.75);
                    });
                  },
                ),

                // 3. Right Pane: Side-by-Side Response Viewer
                SizedBox(
                  width: rightWidth,
                  child: _buildRightPane(context, requestProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResizeHandle({required ValueChanged<double> onDrag}) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) => onDrag(details.delta.dx),
        child: Container(
          width: 6,
          color: theme.dividerColor.withValues(alpha: 0.4),
          child: Center(
            child: Container(
              width: 2,
              height: 24,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedSidebar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            tooltip: 'Expand Sidebar',
            onPressed: () {
              setState(() {
                _isSidebarCollapsed = false;
              });
            },
          ),
          const Divider(height: 1),
          IconButton(
            icon: Icon(Icons.folder_rounded,
                size: 18,
                color: _sidebarIndex == 0 ? theme.colorScheme.primary : null),
            tooltip: 'Collections',
            onPressed: () => setState(() {
              _sidebarIndex = 0;
              _isSidebarCollapsed = false;
            }),
          ),
          IconButton(
            icon: Icon(Icons.history_rounded,
                size: 18,
                color: _sidebarIndex == 1 ? theme.colorScheme.primary : null),
            tooltip: 'History',
            onPressed: () => setState(() {
              _sidebarIndex = 1;
              _isSidebarCollapsed = false;
            }),
          ),
          IconButton(
            icon: Icon(Icons.settings_input_component_rounded,
                size: 18,
                color: _sidebarIndex == 2 ? theme.colorScheme.primary : null),
            tooltip: 'Environments',
            onPressed: () => setState(() {
              _sidebarIndex = 2;
              _isSidebarCollapsed = false;
            }),
          ),
          IconButton(
            icon: Icon(Icons.cable_rounded,
                size: 18,
                color: _sidebarIndex == 3 ? theme.colorScheme.primary : null),
            tooltip: 'WebSocket',
            onPressed: () => setState(() {
              _sidebarIndex = 3;
              _isSidebarCollapsed = false;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          // Sidebar Tab Bar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                _buildSidebarTab(0, Icons.folder_rounded, 'Collections'),
                _buildSidebarTab(1, Icons.history_rounded, 'History'),
                _buildSidebarTab(
                    2, Icons.settings_input_component_rounded, 'Envs'),
                _buildSidebarTab(3, Icons.cable_rounded, 'WS'),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 18),
                  tooltip: 'Collapse Sidebar',
                  onPressed: () {
                    setState(() {
                      _isSidebarCollapsed = true;
                    });
                  },
                ),
              ],
            ),
          ),

          // Sidebar Tab Content
          Expanded(
            child: IndexedStack(
              index: _sidebarIndex,
              children: [
                CollectionsScreen(
                  onRequestTapped: () {},
                ),
                HistoryScreen(
                  onRequestTapped: () {},
                ),
                const EnvironmentsScreen(),
                const WebSocketScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTab(int index, IconData icon, String label) {
    final isSelected = _sidebarIndex == index;
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => setState(() => _sidebarIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPane(
      BuildContext context, RequestProvider requestProvider) {
    return Column(
      children: [
        // Workspace Tab Bar
        const WorkspaceTabBar(),

        // URL & Method Input Bar
        RequestUrlBar(focusNode: _urlFocusNode),

        // Request Configuration Tabs (Params, Auth, Headers, Body, Extractors)
        const Expanded(
          child: RequestTabs(),
        ),

        // Bottom Quick Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ctrl + Enter: Send • Ctrl + S: Save • Ctrl + /: URL',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: requestProvider.isLoading ? null : _sendRequest,
                icon: requestProvider.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 14),
                label: const Text('Send (Ctrl+Enter)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightPane(
      BuildContext context, RequestProvider requestProvider) {
    final theme = Theme.of(context);
    final response = requestProvider.response;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Response Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Text(
                  'RESPONSE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (response != null && !requestProvider.isStreaming) ...[
                  // Status code pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (response.statusCode >= 200 &&
                              response.statusCode < 300)
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${response.statusCode}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: (response.statusCode >= 200 &&
                                response.statusCode < 300)
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${response.responseTimeMs} ms',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    response.sizeFormatted,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),

          // Response Body Content Area
          Expanded(
            child: requestProvider.isStreaming
                ? const StreamingResponseViewer()
                : requestProvider.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Sending request...',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : response != null
                        ? const ResponseViewer()
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 48,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Ready to Send Request',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Press Ctrl + Enter or click Send',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
