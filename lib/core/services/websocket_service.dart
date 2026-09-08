import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:youmatter_mobile/core/config/app_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;

  void connect(String token) {
    final wsUrl = '${AppConfig.wsUrl}/app/${AppConfig.reverbAppKey}?auth=$token';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _isConnected = true;

    _channel!.stream.listen(
      (message) {
        _handleMessage(message);
      },
      onError: (error) {
        _isConnected = false;
      },
      onDone: () {
        _isConnected = false;
      },
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }

  void subscribeToConversation(String conversationId) {
    if (_isConnected) {
      _channel?.sink.add(jsonEncode({
        'event': 'pusher:subscribe',
        'data': jsonEncode({'channel': 'conversation.$conversationId'}),
      }));
    }
  }

  void _handleMessage(dynamic message) {
    // Parse and dispatch events to Riverpod providers
  }

  bool get isConnected => _isConnected;
}
