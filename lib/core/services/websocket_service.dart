import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:youmatter_mobile/core/config/app_config.dart';
import 'package:youmatter_mobile/core/services/auth_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  final AuthService _authService = AuthService();

  /// Callback for incoming call events.
  void Function(Map<String, dynamic> data)? onIncomingCall;
  void Function(Map<String, dynamic> data)? onCallAccepted;
  void Function(Map<String, dynamic> data)? onCallDeclined;
  void Function(Map<String, dynamic> data)? onCallEnded;
  void Function(Map<String, dynamic> data)? onWebRtcOffer;
  void Function(Map<String, dynamic> data)? onWebRtcAnswer;
  void Function(Map<String, dynamic> data)? onIceCandidate;

  Future<void> connect() async {
    final token = await _authService.getToken();
    if (token == null) return;

    final wsUrl = '${AppConfig.wsUrl}/app/${AppConfig.reverbAppKey}?auth=$token';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _isConnected = true;

    _channel!.stream.listen(
      _handleMessage,
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
    try {
      final data = jsonDecode(message as String);
      final event = data['event'] as String?;

      switch (event) {
        case 'App\\Events\\Voice\\IncomingCall':
        case 'incoming_call':
          onIncomingCall?.call(data['data'] ?? {});
          break;
        case 'App\\Events\\Voice\\CallAccepted':
        case 'call_accepted':
          onCallAccepted?.call(data['data'] ?? {});
          break;
        case 'App\\Events\\Voice\\CallDeclined':
        case 'call_declined':
          onCallDeclined?.call(data['data'] ?? {});
          break;
        case 'App\\Events\\Voice\\CallEnded':
        case 'call_ended':
          onCallEnded?.call(data['data'] ?? {});
          break;
        case 'App\\Events\\Voice\\WebRtcOffer':
        case 'webrtc.offer':
          onWebRtcOffer?.call(data['data'] ?? {});
          break;
        case 'App\\Events\\Voice\\WebRtcAnswer':
        case 'webrtc.answer':
          onWebRtcAnswer?.call(data['data'] ?? {});
          break;
        case 'App\\Events\\Voice\\IceCandidate':
        case 'webrtc.ice-candidate':
          onIceCandidate?.call(data['data'] ?? {});
          break;
      }
    } catch (e) {
      // Ignore malformed messages.
    }
  }

  bool get isConnected => _isConnected;
}
