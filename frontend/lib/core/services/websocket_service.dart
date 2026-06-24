import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

/// Real-time notification service via WebSocket to the Go server.
///
/// Connects to ws://host:9000/ws?token=... and listens for notification
/// events pushed from Laravel → Redis pub/sub → Go → WebSocket.
class WebSocketService {
  WebSocketService._();
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _intentionalClose = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  /// Stream of incoming notification events.
  /// Widgets can listen to this to update UI in real-time.
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;

  /// Current connection state.
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Connect to the Go WebSocket server.
  void connect() {
    final token = ApiService().token;
    if (token == null || token.isEmpty) {
      debugPrint('[WS] Cannot connect: no auth token');
      return;
    }

    _intentionalClose = false;
    _doConnect(token);
  }

  void _doConnect(String token) {
    try {
      // Build WebSocket URL from imageBaseUrl (same Go server)
      final httpUrl = ApiConstants.imageBaseUrl;
      final wsUrl = httpUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');

      final uri = Uri.parse('$wsUrl/ws?token=$token');
      debugPrint('[WS] Connecting to $uri');

      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onDone: _onDone,
        onError: _onError,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('[WS] ✅ Connected');
    } catch (e) {
      debugPrint('[WS] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'connected') {
        debugPrint('[WS] Server confirmed connection: ${data['message']}');
        return;
      }

      if (type == 'notification') {
        final notifData = data['data'] as Map<String, dynamic>?;
        if (notifData != null) {
          debugPrint('[WS] 🔔 Notification received: ${notifData['title']}');
          _notificationController.add(notifData);
        }
      }
    } catch (e) {
      debugPrint('[WS] Message parse error: $e');
    }
  }

  void _onDone() {
    _isConnected = false;
    debugPrint('[WS] Connection closed');
    if (!_intentionalClose) {
      _scheduleReconnect();
    }
  }

  void _onError(dynamic error) {
    _isConnected = false;
    debugPrint('[WS] Error: $error');
    if (!_intentionalClose) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_intentionalClose) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WS] Max reconnect attempts reached, giving up');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;
    debugPrint('[WS] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      final token = ApiService().token;
      if (token != null && token.isNotEmpty) {
        _doConnect(token);
      }
    });
  }

  /// Disconnect from the WebSocket server.
  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _reconnectAttempts = 0;
    debugPrint('[WS] 👋 Disconnected');
  }

  /// Dispose the service (call on app shutdown).
  void dispose() {
    disconnect();
    _notificationController.close();
  }
}
