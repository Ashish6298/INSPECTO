import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global keyboard shortcut activators for the Inspecto desktop workstation.
class AppKeyboardShortcuts {
  // Send Request (Ctrl + Enter / Cmd + Enter)
  static const sendRequestCtrl =
      SingleActivator(LogicalKeyboardKey.enter, control: true);
  static const sendRequestMeta =
      SingleActivator(LogicalKeyboardKey.enter, meta: true);

  // Save Request (Ctrl + S / Cmd + S)
  static const saveRequestCtrl =
      SingleActivator(LogicalKeyboardKey.keyS, control: true);
  static const saveRequestMeta =
      SingleActivator(LogicalKeyboardKey.keyS, meta: true);

  // New Tab (Ctrl + T / Cmd + T)
  static const newTabCtrl =
      SingleActivator(LogicalKeyboardKey.keyT, control: true);
  static const newTabMeta =
      SingleActivator(LogicalKeyboardKey.keyT, meta: true);

  // Close Active Tab (Ctrl + W / Cmd + W)
  static const closeTabCtrl =
      SingleActivator(LogicalKeyboardKey.keyW, control: true);
  static const closeTabMeta =
      SingleActivator(LogicalKeyboardKey.keyW, meta: true);

  // Focus URL Bar (Ctrl + / or Cmd + /)
  static const focusUrlCtrl =
      SingleActivator(LogicalKeyboardKey.slash, control: true);
  static const focusUrlMeta =
      SingleActivator(LogicalKeyboardKey.slash, meta: true);
}

/// Declarative widget wrapper that binds application-wide keyboard shortcuts
class GlobalKeyboardShortcutsHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback onSendRequest;
  final VoidCallback onSaveRequest;
  final VoidCallback onNewTab;
  final VoidCallback onCloseTab;
  final VoidCallback onFocusUrl;

  const GlobalKeyboardShortcutsHandler({
    super.key,
    required this.child,
    required this.onSendRequest,
    required this.onSaveRequest,
    required this.onNewTab,
    required this.onCloseTab,
    required this.onFocusUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        AppKeyboardShortcuts.sendRequestCtrl: onSendRequest,
        AppKeyboardShortcuts.sendRequestMeta: onSendRequest,
        AppKeyboardShortcuts.saveRequestCtrl: onSaveRequest,
        AppKeyboardShortcuts.saveRequestMeta: onSaveRequest,
        AppKeyboardShortcuts.newTabCtrl: onNewTab,
        AppKeyboardShortcuts.newTabMeta: onNewTab,
        AppKeyboardShortcuts.closeTabCtrl: onCloseTab,
        AppKeyboardShortcuts.closeTabMeta: onCloseTab,
        AppKeyboardShortcuts.focusUrlCtrl: onFocusUrl,
        AppKeyboardShortcuts.focusUrlMeta: onFocusUrl,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
