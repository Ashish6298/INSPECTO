import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/history_item.dart';

class HistoryLocalDataSource {
  static const String _keyHistory = 'inspecto_request_history';
  static const int maxHistoryItems = 100;

  Future<List<HistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_keyHistory);
      if (historyJson == null) return [];

      return historyJson
          .map((itemStr) =>
              HistoryItem.fromJson(jsonDecode(itemStr) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistoryItem(HistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      // Add to front
      history.insert(0, item);

      // Trim to maximum limit
      if (history.length > maxHistoryItems) {
        history.removeRange(maxHistoryItems, history.length);
      }

      final encoded =
          history.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_keyHistory, encoded);
    } catch (_) {}
  }

  Future<void> deleteHistoryItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      history.removeWhere((item) => item.id == id);
      final encoded =
          history.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_keyHistory, encoded);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyHistory);
    } catch (_) {}
  }
}
