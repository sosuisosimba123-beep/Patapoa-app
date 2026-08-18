import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;

  /// Connects to the Laravel Reverb / WebSocket server
  void connect() {
    if (_isConnected) return;

    final wsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws').replaceFirst('/api/v1', '/app/patapoa-key');
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      debugPrint('WebSocket Connected to $wsUrl');
    } catch (e) {
      debugPrint('WebSocket Connection Error: $e');
    }
  }

  /// Listens for partner location updates for a specific order
  Stream<dynamic> listenToPartnerLocation(int partnerId) {
    if (!_isConnected) connect();

    // Reverb/Pusher subscription format
    final subscribeMessage = jsonEncode({
      'event': 'pusher:subscribe',
      'data': {'channel': 'partner-location.$partnerId'}
    });

    _channel?.sink.add(subscribeMessage);

    return _channel!.stream.map((event) {
      final data = jsonDecode(event);
      if (data['event'] == 'location.updated') {
        return jsonDecode(data['data']);
      }
      return null;
    }).where((event) => event != null);
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
}
