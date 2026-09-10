/// A source of realtime call-signaling events.
///
/// Concrete transports deliver `IncomingCall` / `WebRtcOffer` / `WebRtcAnswer`
/// / `IceCandidate` / `CallAccepted` / `CallDeclined` / `CallEnded` events to a
/// subscribing client. The app prefers the Pusher transport and falls back to
/// polling when no realtime socket can be established ([CallSignalingCoordinator]).
abstract class CallTransport {
  /// Broadcast event callbacks. Payloads match the backend `broadcastWith`
  /// shapes (e.g. `{from_user_id, offer}` / `{id, initiated_by, ...}`).
  void Function(Map<String, dynamic> data)? onIncomingCall;
  void Function(Map<String, dynamic> data)? onOffer;
  void Function(Map<String, dynamic> data)? onAnswer;
  void Function(Map<String, dynamic> data)? onIceCandidate;
  void Function(Map<String, dynamic> data)? onCallAccepted;
  void Function(Map<String, dynamic> data)? onCallDeclined;
  void Function(Map<String, dynamic> data)? onCallEnded;

  /// Human-readable transport name, for logging/debugging.
  String get name;

  /// Connect (or otherwise prepare) the transport.
  Future<void> connect() async {}

  /// Whether the transport is connected and ready to receive events.
  bool get isReady => false;

  /// Subscribe to a conversation's private channel for call signaling.
  Future<void> subscribeToConversation(String conversationId) async {}

  /// Unsubscribe from a conversation's private channel. A `null` [conversationId]
  /// is a no-op.
  void unsubscribeFromConversation(String? conversationId) {}

  /// Stop the transport and release resources.
  Future<void> dispose() async {}
}

/// Routes an event name + payload to the matching callback on the given [CallTransport].
/// Returns `false` if the event was not a call-signaling event.
bool routeCallEvent(CallTransport transport, String? event, Map<String, dynamic>? payload) {
  if (event == null || payload == null) return false;

  if (event.endsWith('IncomingCall')) {
    transport.onIncomingCall?.call(payload);
    return true;
  } else if (event.endsWith('WebRtcOffer')) {
    transport.onOffer?.call(payload);
    return true;
  } else if (event.endsWith('WebRtcAnswer')) {
    transport.onAnswer?.call(payload);
    return true;
  } else if (event.endsWith('IceCandidate')) {
    transport.onIceCandidate?.call(payload);
    return true;
  } else if (event.endsWith('CallAccepted')) {
    transport.onCallAccepted?.call(payload);
    return true;
  } else if (event.endsWith('CallDeclined')) {
    transport.onCallDeclined?.call(payload);
    return true;
  } else if (event.endsWith('CallEnded')) {
    transport.onCallEnded?.call(payload);
    return true;
  }
  return false;
}