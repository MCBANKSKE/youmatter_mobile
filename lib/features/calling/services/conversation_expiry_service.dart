import 'dart:async';

import 'package:youmatter_mobile/core/networking/api_service.dart';

/// Periodically checks the server for conversation status changes.
///
/// Conversations are supposed to auto-end after 1 hour, but the backend
/// relies on a queued `ExpireConversationJob` (and a 5-minute scheduler
/// fallback). When the queue worker is offline or the mobile app has been
/// backgrounded for a long time, the client may still show an "active"
/// conversation that the server has already ended.
///
/// This service polls every 20-30 minutes and surfaces a
/// `conversationEnded` callback whenever the server reports a conversation
/// has transitioned to `ended`. The caller is responsible for refreshing
/// UI / tearing down an active WebRTC call.
class ConversationExpiryService {
  ConversationExpiryService(this._api);

  final ApiService _api;

  static const Duration _interval = Duration(minutes: 25);

  Timer? _timer;
  String? _conversationId;
  bool _wasActive = false;

  /// Start polling a specific conversation for status changes.
  void watchConversation(String conversationId) {
    if (_conversationId == conversationId && _timer != null) return;
    _conversationId = conversationId;
    _wasActive = false;
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => unawaited(_poll()));
    unawaited(_poll());
  }

  /// Stop polling.
  void stopWatching() {
    _timer?.cancel();
    _timer = null;
    _conversationId = null;
    _wasActive = false;
  }

  /// Fired when the server reports the conversation is no longer active.
  void Function(Map<String, dynamic> status)? onConversationEnded;

  Future<void> _poll() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;

    try {
      final status = await _api.getConversationStatus(conversationId);
      final isActive = status['status'] == 'active';

      if (_wasActive && !isActive) {
        onConversationEnded?.call(status);
      }
      _wasActive = isActive;
    } catch (_) {
      // Transient failure — keep retrying on the next tick.
    }
  }

  void dispose() {
    stopWatching();
    onConversationEnded = null;
  }
}