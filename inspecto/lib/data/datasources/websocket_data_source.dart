import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class WebSocketFrame {
  final String id;
  final DateTime timestamp;
  final bool isInbound; // true for received from server, false for sent by client
  final String payload;
  final int byteLength;

  WebSocketFrame({
    required this.id,
    required this.timestamp,
    required this.isInbound,
    required this.payload,
    required this.byteLength,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'isInbound': isInbound,
        'payload': payload,
        'byteLength': byteLength,
      };

  factory WebSocketFrame.fromJson(Map<String, dynamic> json) => WebSocketFrame(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isInbound: json['isInbound'] as bool,
        payload: json['payload'] as String,
        byteLength: json['byteLength'] as int,
      );
}

class WebSocketDataSource {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  WebSocketStatus _currentStatus = WebSocketStatus.disconnected;
  final StreamController<WebSocketStatus> _statusController =
      StreamController<WebSocketStatus>.broadcast();
  final StreamController<WebSocketFrame> _frameController =
      StreamController<WebSocketFrame>.broadcast();

  WebSocketStatus get currentStatus => _currentStatus;
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  Stream<WebSocketFrame> get frameStream => _frameController.stream;

  Future<void> connect(String url) async {
    await disconnect();

    _setStatus(WebSocketStatus.connecting);

    try {
      final uri = Uri.parse(url.trim());
      if (!uri.isScheme('ws') && !uri.isScheme('wss')) {
        throw const FormatException('URL must use ws:// or wss:// scheme');
      }

      _channel = WebSocketChannel.connect(uri);

      // Await ready to confirm handshake
      await _channel!.ready;
      _setStatus(WebSocketStatus.connected);

      _subscription = _channel!.stream.listen(
        (data) {
          final payloadStr = data is List<int>
              ? utf8.decode(data, allowMalformed: true)
              : data.toString();

          final frame = WebSocketFrame(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            isInbound: true,
            payload: payloadStr,
            byteLength: utf8.encode(payloadStr).length,
          );
          _frameController.add(frame);
        },
        onError: (err) {
          _setStatus(WebSocketStatus.error);
        },
        onDone: () {
          _setStatus(WebSocketStatus.disconnected);
        },
        cancelOnError: false,
      );
    } catch (e) {
      _setStatus(WebSocketStatus.error);
      rethrow;
    }
  }

  void send(String message) {
    if (_currentStatus != WebSocketStatus.connected || _channel == null) {
      throw StateError('Cannot send frame: WebSocket is not connected');
    }

    _channel!.sink.add(message);

    final frame = WebSocketFrame(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      isInbound: false,
      payload: message,
      byteLength: utf8.encode(message).length,
    );
    _frameController.add(frame);
  }

  Future<void> disconnect({int? closeCode, String? closeReason}) async {
    await _subscription?.cancel();
    _subscription = null;

    if (_channel != null) {
      await _channel!.sink.close(closeCode, closeReason);
      _channel = null;
    }

    _setStatus(WebSocketStatus.disconnected);
  }

  void _setStatus(WebSocketStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _frameController.close();
  }
}
