import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static StreamSubscription? _subscription;
  static String? _currentFactoryId;
  static final List<Function(Map<String, dynamic>)> _listeners = [];

  /// WebSocket URL
  static String get wsUrl {
    // Use the same port as the API server (3001)
    return 'ws://localhost:3001';
  }

  /// Connect to WebSocket server
  static void connect(String factoryId) {
    if (_currentFactoryId == factoryId && _channel != null) {
      debugPrint('✓ Already connected to WebSocket for factory $factoryId');
      return;
    }

    disconnect();
    _currentFactoryId = factoryId;

    try {
      debugPrint('🔌 Connecting to WebSocket: $wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Subscribe to factory notifications
      _channel!.sink.add(jsonEncode({
        'type': 'subscribe',
        'factoryId': factoryId,
      }));

      // Listen to messages
      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            debugPrint('📨 WebSocket message received: $data');
            
            // Notify all listeners
            for (var listener in _listeners) {
              listener(data);
            }
          } catch (e) {
            debugPrint('❌ Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ WebSocket error: $error');
        },
        onDone: () {
          debugPrint('🔌 WebSocket connection closed');
          _channel = null;
        },
      );

      debugPrint('✓ WebSocket connected for factory $factoryId');
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
    }
  }

  /// Disconnect from WebSocket
  static void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    _currentFactoryId = null;
    debugPrint('🔌 WebSocket disconnected');
  }

  /// Add a listener for WebSocket messages
  static void addListener(Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  static void removeListener(Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  /// Check if connected
  static bool get isConnected => _channel != null;
}
