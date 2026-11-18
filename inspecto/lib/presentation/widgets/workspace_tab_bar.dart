import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/api_request.dart';
import '../providers/workspace_provider.dart';
import '../providers/request_provider.dart';

class WorkspaceTabBar extends StatelessWidget {
  const WorkspaceTabBar({super.key});

  Color _getMethodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.GET:
        return const Color(0xFF2ECC71); // Green
      case HttpMethod.POST:
        return const Color(0xFFF39C12); // Orange / Amber
      case HttpMethod.PUT:
        return const Color(0xFF3498DB); // Blue
      case HttpMethod.DELETE:
        return const Color(0xFFE74C3C); // Red
      case HttpMethod.PATCH:
        return const Color(0xFF9B59B6); // Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final wsProvider = context.watch<WorkspaceProvider>();
    final reqProvider = context.read<RequestProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFECEFF4),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Scrollable Tabs Area
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: wsProvider.tabs.length,
              itemBuilder: (context, index) {
                final tab = wsProvider.tabs[index];
                final isActive = index == wsProvider.activeTabIndex;
                final methodColor = _getMethodColor(tab.method);

                return GestureDetector(
                  onTap: () {
                    wsProvider.switchTab(index, requestProvider: reqProvider);
                  },
                  onSecondaryTapUp: (details) {
                    _showTabContextMenu(
                      context,
                      details.globalPosition,
                      index,
                      wsProvider,
                      reqProvider,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isDark
                              ? theme.colorScheme.surface
                              : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Method indicator
                        Text(
                          tab.method.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: methodColor,
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Title text
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            tab.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                            ),
                          ),
                        ),

                        // Dirty indicator
                        if (tab.isDirty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ),

                        const SizedBox(width: 4),

                        // Close button
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            wsProvider.closeTab(index,
                                requestProvider: reqProvider);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // New Tab Button (+)
          Tooltip(
            message: 'New Request Tab (Ctrl+T)',
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                wsProvider.newTab(requestProvider: reqProvider);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                child: const Icon(Icons.add, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTabContextMenu(
    BuildContext context,
    Offset position,
    int index,
    WorkspaceProvider wsProvider,
    RequestProvider reqProvider,
  ) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 16),
              SizedBox(width: 8),
              Text('Duplicate Tab'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'close_others',
          child: Row(
            children: [
              Icon(Icons.tab_unselected, size: 16),
              SizedBox(width: 8),
              Text('Close Other Tabs'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'close',
          child: Row(
            children: [
              Icon(Icons.close, size: 16),
              SizedBox(width: 8),
              Text('Close Tab'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'duplicate') {
        wsProvider.duplicateTab(index, requestProvider: reqProvider);
      } else if (value == 'close_others') {
        wsProvider.closeOtherTabs(index, requestProvider: reqProvider);
      } else if (value == 'close') {
        wsProvider.closeTab(index, requestProvider: reqProvider);
      }
    });
  }
}
