import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:youmatter_mobile/core/config/app_config.dart';
import 'package:youmatter_mobile/core/services/auth_service.dart';

/// Service that handles call signaling over the Reverb WebSocket.
///
/// This translates between the WebRTC service and the Laravel backend.
/// It sends and receives:
/// - WebRTC offers
/// - WebRTC answers
/// - ICE candidates
class CallSignalingService {
  final AuthService _authService = AuthService();
  WebSocketChannel? _channel;

  /// Connect to the Reverb WebSocket for signaling.
  Future<void> connect() async {
    final token = await _authService.getToken();
    if (token == null) return;

    final wsUrl = '${AppConfig.wsUrl}/app/${AppConfig.reverbAppKey}?auth=$token';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      _handleMessage,
      onError: (error) {
        // Connection error.
      },
      onDone: () {
        // Connection closed.
      },
    );
  }

  /// Subscribe to a conversation channel for call signaling.
  void subscribeToConversation(String conversationId) {
    _channel?.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': jsonEncode({'channel': 'conversation.$conversationId'}),
    }));
  }

  /// Send a WebRTC offer to the other participant.
  void sendOffer({
    required int conversationId,
    required Map<String, dynamic> offer,
    required int fromUserId,
  }) {
    _channel?.sink.add(jsonEncode({
      'event': 'webrtc.offer',
      'channel': 'conversation.$conversationId',
      'data': jsonEncode({
        'offer': offer,
        'from_user_id': fromUserId,
      }),
    }));
  }

  /// Send a WebRTC answer to the other participant.
  void sendAnswer({
    required int conversationId,
    required Map<String, dynamic> answer,
    required int fromUserId,
  }) {
    _channel?.sink.add(jsonEncode({
      'event': 'webrtc.answer',
      'channel': 'conversation.$conversationId',
      'data': jsonEncode({
        'answer': answer,
        'from_user_id': fromUserId,
      }),
    }));
  }

  /// Send an ICE candidate to the other participant.
  void sendIceCandidate({
    required int conversationId,
    required Map<String, dynamic> candidate,
    required int fromUserId,
  }) {
    _channel?.sink.add(jsonEncode({
      'event': 'webrtc.ice-candidate',
      'channel': 'conversation.$conversationId',
      'data': jsonEncode({
        'candidate': candidate,
        'from_user_id': fromUserId,
      }),
    }));
  }

  /// Handle incoming signaling messages.
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final event = data['event'] as String?;

      switch (event) {
        case 'webrtc.offer':
          _handleOffer(data['data']);
          break;
        case 'webrtc.answer':
          _handleAnswer(data['data']);
          break;
        case 'webrtc.ice-candidate':
          _handleIceCandidate(data['data']);
          break;
      }
    } catch (e) {
      // Ignore malformed messages.
    }
  }

  void _handleOffer(dynamic data) {
    // Offer received — to be handled by the call controller.
  }

  void _handleAnswer(dynamic data) {
    // Answer received — to be handled by the call controller.
  }

  void _handleIceCandidate(dynamic data) {
    // ICE candidate received — to be handled by the call controller.
  }

  /// Disconnect from the WebSocket.
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}