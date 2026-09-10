import 'dart:async';

import 'package:youmatter_mobile/core/networking/api_service.dart';
import 'package:youmatter_mobile/core/services/auth_service.dart';

import 'call_transport.dart';

/// Polling fallback transport for call signaling.
///
/// Used when a realtime (Pusher/Reverb) socket cannot be established. It polls
/// the backend for the conversation's active call and drains WebRTC signaling
/// messages delivered via REST, surfacing the same callbacks as the realtime
/// transport.
class PollingCallSignalingService extends CallTransport {
  static const Duration _interval = Duration(seconds: 2);

  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();

  int? _cachedUserId;
  Timer? _timer;
  String? _conversationId;
  int? _seenCallId;
  int _signalAfterId = 0;
  bool _sawActiveCall = false;

  @override
  String get name => 'polling';

  @override
  bool get isReady => _timer != null;

  @override
  Future<void> connect() async {
    // No-op for polling; the subscription loop starts the work.
  }

  @override
  Future<void> subscribeToConversation(String conversationId) async {
    if (_conversationId == conversationId && _timer != null) return;
    _conversationId = conversationId;
    _seenCallId = null;
    _signalAfterId = 0;
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (Timer timer) {
      unawaited(_poll());
    });
  }

  @override
  void unsubscribeFromConversation(String? conversationId) {
    if (_conversationId == conversationId) {
      _timer?.cancel();
      _timer = null;
      _conversationId = null;
      _seenCallId = null;
    }
  }

  Future<void> _poll() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;

    try {
      final state = await _api.getCallState(conversationId);

      if (state == null) {
        // A previously-seen call ended (or was declined / missed).
        if (_seenCallId != null) {
          _seenCallId = null;
          _signalAfterId = 0;
          _sawActiveCall = false;
          onCallEnded?.call({
            'conversation_id': int.tryParse(conversationId),
            'status': 'ended',
          });
        }
        return;
      }

      final callId = state['id'] as int? ?? 0;
      final status = state['status']?.toString() ?? '';
      final initiatedBy = state['initiated_by'] as int?;
      final myId = await _myUserId();

      if (_seenCallId == null) {
        // A new call appeared for this conversation.
        _seenCallId = callId;
        _signalAfterId = 0;

        // Only surface an incoming-call to the party that did NOT initiate it.
        if (initiatedBy != null && myId != null && initiatedBy != myId) {
          onIncomingCall?.call({
            'id': callId,
            'conversation_id': state['conversation_id'],
            'initiated_by': initiatedBy,
            'status': status,
            'started_at': state['started_at'],
          });
        }
        _sawActiveCall = status == 'active';
      } else if (status == 'active' && !_sawActiveCall) {
        _sawActiveCall = true;
        onCallAccepted?.call({'id': callId, 'status': 'active'});
      }

      if (callId != 0) await _drainSignals(callId);
    } catch (e) {
      // A transient polling failure is harmless; keep retrying.
    }
  }

  Future<void> _drainSignals(int callId) async {
    final (messages, lastId) = await _api.getCallSignals(
      callId,
      _signalAfterId,
    );
    if (lastId > _signalAfterId) _signalAfterId = lastId;

    for (final raw in messages) {
      final message = raw as Map<String, dynamic>;
      final event = message['event']?.toString() ?? '';
      final payload = message['payload'] as Map<String, dynamic>?;
      final fromUserId = message['from_user_id'] as int?;
      if (payload == null && event != 'ice') continue;

      switch (event) {
        case 'offer':
          onOffer?.call({'from_user_id': fromUserId, 'offer': payload});
          break;
        case 'answer':
          onAnswer?.call({'from_user_id': fromUserId, 'answer': payload});
          break;
        case 'ice':
          onIceCandidate?.call({
            'from_user_id': fromUserId,
            'candidate': payload,
          });
          break;
      }
    }
  }

  Future<int?> _myUserId() async {
    final cached = _cachedUserId;
    if (cached != null) return cached;
    final user = await _authService.getUserData();
    final id = user == null
        ? null
        : int.tryParse(user['id']?.toString() ?? '');
    _cachedUserId = id;
    return id;
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    _conversationId = null;
    _seenCallId = null;
  }
}