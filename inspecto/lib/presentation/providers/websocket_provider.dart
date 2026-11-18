import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/datasources/websocket_data_source.dart';

class WebSocketProvider with ChangeNotifier {
  final WebSocketDataSource dataSource;

  WebSocketProvider({required this.dataSource}) {
    _statusSub = dataSource.statusStream.listen((status) {
      _status = status;
      if (status == WebSocketStatus.connected) {
        _errorMessage = null;
      }
      notifyListeners();
    });

    _frameSub = dataSource.frameStream.listen((frame) {
      _frames.insert(0, frame); // Newest frames on top
      notifyListeners();
    });
  }

  StreamSubscription? _statusSub;
  StreamSubscription? _frameSub;

  String _url = 'wss://echo.websocket.org';
  WebSocketStatus _status = WebSocketStatus.disconnected;
  final List<WebSocketFrame> _frames = [];
  String _filter = 'all'; // 'all', 'inbound', 'outbound'
  String _searchQuery = '';
  String? _errorMessage;

  String get url => _url;
  WebSocketStatus get status => _status;
  List<WebSocketFrame> get frames => _frames;
  String get filter => _filter;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  int get inboundCount => _frames.where((f) => f.isInbound).length;
  int get outboundCount => _frames.where((f) => !f.isInbound).length;

  List<WebSocketFrame> get filteredFrames {
    return _frames.where((frame) {
      if (_filter == 'inbound' && !frame.isInbound) return false;
      if (_filter == 'outbound' && frame.isInbound) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return frame.payload.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  void setUrl(String url) {
    _url = url;
    notifyListeners();
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> connect({String? customUrl}) async {
    final targetUrl = customUrl ?? _url;
    _errorMessage = null;
    notifyListeners();

    try {
      await dataSource.connect(targetUrl);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await dataSource.disconnect();
    _errorMessage = null;
    notifyListeners();
  }

  void sendMessage(String message) {
    if (message.trim().isEmpty) return;
    try {
      dataSource.send(message);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearFrames() {
    _frames.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _frameSub?.cancel();
    dataSource.dispose();
    super.dispose();
  }
}
