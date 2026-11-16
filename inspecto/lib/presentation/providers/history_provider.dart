import 'package:flutter/material.dart';
import '../../domain/entities/api_request.dart';
import '../../domain/entities/api_response.dart';
import '../../domain/entities/history_item.dart';
import '../../data/datasources/history_local_data_source.dart';

class HistoryProvider with ChangeNotifier {
  final HistoryLocalDataSource dataSource;

  HistoryProvider({required this.dataSource});

  List<HistoryItem> _history = [];
  bool _isLoading = false;

  List<HistoryItem> get history => _history;
  bool get isLoading => _isLoading;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    _history = await dataSource.getHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry({
    required ApiRequest request,
    required ApiResponse response,
  }) async {
    final entry = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      request: request,
      statusCode: response.statusCode,
      responseTimeMs: response.responseTimeMs,
      responseSize: response.responseSize,
    );

    _history.insert(0, entry);
    if (_history.length > HistoryLocalDataSource.maxHistoryItems) {
      _history.removeLast();
    }
    notifyListeners();

    await dataSource.saveHistoryItem(entry);
  }

  Future<void> deleteEntry(String id) async {
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
    await dataSource.deleteHistoryItem(id);
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    await dataSource.clearHistory();
  }
}
