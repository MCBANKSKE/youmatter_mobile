import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:youmatter_mobile/core/config/app_config.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';
import 'package:youmatter_mobile/core/services/auth_service.dart';

/// Service that handles call signaling over the Reverb WebSocket.
///
/// Translates between the WebRTC service and the Laravel backend:
/// - Authenticates private conversation channels through Laravel's signed
///   `/broadcasting/auth` endpoint (Reverb rejects raw bearer tokens).
/// - Receives broadcast call events (incoming call, WebRTC offer/answer,
///   ICE candidates, call lifecycle) and surfaces them via callbacks.
///
/// Sending signaling payloads is done over REST (see `ApiService.sendSignal`)
/// because Reverb does not accept client-published messages.
class CallSignalingService {
  final AuthService _authService = AuthService();
  final ApiService _api = ApiService();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String? _socketId;
  bool _isConnected = false;
  final Set<String> _subscribedChannels = {};
  final List<String> _pendingChannels = [];

  /// Broadcast event callbacks. Payloads match the backend broadcastWith
  /// shape (e.g. `{from_user_id, offer}` / `{id, initiated_by, ...}`).
  void Function(Map<String, dynamic> data)? onIncomingCall;
  void Function(Map<String, dynamic> data)? onOffer;
  void Function(Map<String, dynamic> data)? onAnswer;
  void Function(Map<String, dynamic> data)? onIceCandidate;
  void Function(Map<String, dynamic> data)? onCallAccepted;
  void Function(Map<String, dynamic> data)? onCallDeclined;
  void Function(Map<String, dynamic> data)? onCallEnded;

  bool get isConnected => _isConnected;

  /// Connect to the Reverb WebSocket for signaling.
  Future<void> connect() async {
    if (_isConnected) return;

    final token = await _authService.getToken();
    if (token == null) return;

    try {
      final wsUrl = '${AppConfig.wsUrl}/app/${AppConfig.reverbAppKey}'
          '?protocol=7&client=flutter&version=1.0.0';

      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (Object error) => _reset(),
        onDone: _reset,
      );
    } catch (e) {
      _reset();
    }
  }

  /// Subscribe to a conversation's private channel for call signaling.
  Future<void> subscribeToConversation(String conversationId) =>
      _subscribe('conversation.$conversationId');

  /// Unsubscribe from a conversation channel (e.g. when a call ends).
  void unsubscribeFromConversation(String? conversationId) {
    if (conversationId == null) return;
    final channelName = 'conversation.$conversationId';
    _subscribedChannels.remove(channelName);
    _channel?.sink.add(
      jsonEncode({
        'event': 'pusher:unsubscribe',
        'data': {'channel': channelName},
      }),
    );
  }

  Future<void> _subscribe(String channelName) async {
    if (_subscribedChannels.contains(channelName)) return;

    // The socket_id is only known once the server says hello; queue the
    // channel until then so early events are not missed.
    if (!_isConnected || _socketId == null) {
      if (!_pendingChannels.contains(channelName)) {
        _pendingChannels.add(channelName);
      }
      return;
    }

    final auth = await _requestChannelAuth(channelName);
    if (auth == null) return;

    _subscribedChannels.add(channelName);
    _channel?.sink.add(
      jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'auth': auth, 'channel': channelName},
      }),
    );
  }

  /// Ask Laravel for a signed private-channel authorization. The request is
  /// authenticated with the Sanctum bearer token by DioClient.
  Future<String?> _requestChannelAuth(String channelName) async {
    final socketId = _socketId;
    if (socketId == null) return null;

    try {
      final response = await _api.authorizeChannel(socketId, channelName);
      final auth = response['auth'];
      return auth is String ? auth : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _flushPendingSubscriptions() async {
    if (_pendingChannels.isEmpty) return;

    final channels = List<String>.from(_pendingChannels);
    _pendingChannels.clear();

    for (final channel in channels) {
      await _subscribe(channel);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>?;
      if (data == null) return;

      final event = data['event'] as String?;
      final payload = _extractPayload(data['data']);
      final channel = data['channel'] as String?;

      switch (event) {
        case 'pusher:connection_established':
          _socketId = payload?['socket_id'] as String?;
          _isConnected = true;
          unawaited(_flushPendingSubscriptions());
          break;
        case 'pusher:ping':
          _channel?.sink.add(jsonEncode({'event': 'pusher:pong', 'data': {}}));
          break;
        case 'pusher:subscription_error':
          if (channel != null) _subscribedChannels.remove(channel);
          break;
        default:
          _handleBroadcastEvent(event, payload);
      }
    } catch (e) {
      // Ignore malformed messages.
    }
  }

  /// Route backend broadcast events by their short class name. Laravel sends
  /// the fully-qualified name (e.g. `App\Events\Voice\WebRtcOffer`); matching
  /// on the suffix avoids hardcoding backslashes.
  void _handleBroadcastEvent(
    String? event,
    Map<String, dynamic>? payload,
  ) {
    if (event == null || payload == null) return;

    if (event.endsWith('IncomingCall')) {
      onIncomingCall?.call(payload);
    } else if (event.endsWith('WebRtcOffer')) {
      onOffer?.call(payload);
    } else if (event.endsWith('WebRtcAnswer')) {
      onAnswer?.call(payload);
    } else if (event.endsWith('IceCandidate')) {
      onIceCandidate?.call(payload);
    } else if (event.endsWith('CallAccepted')) {
      onCallAccepted?.call(payload);
    } else if (event.endsWith('CallDeclined')) {
      onCallDeclined?.call(payload);
    } else if (event.endsWith('CallEnded')) {
      onCallEnded?.call(payload);
    }
  }

  /// Pusher protocol wraps broadcast payloads as a JSON-encoded string.
  Map<String, dynamic>? _extractPayload(dynamic data) {
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return decoded is Map<String, dynamic> ? decoded : null;
      } catch (e) {
        return null;
      }
    }
    return data is Map<String, dynamic> ? data : null;
  }

  void _reset() {
    _isConnected = false;
    _socketId = null;
    _subscribedChannels.clear();
  }

  /// Disconnect from the WebSocket.
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _reset();
    _pendingChannels.clear();
  }
}