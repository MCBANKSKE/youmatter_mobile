import 'dart:async';

import 'call_signaling_service.dart';
import 'call_transport.dart';
import 'polling_call_signaling_service.dart';

/// Routes call-signaling events to the best available transport.
///
/// Connects the Pusher/Reverb WebSocket first; if that cannot be established,
/// it transparently falls back to the polling transport for the remainder of
/// the session. Consumers bind to this coordinator's callbacks (via the
/// `callSignalingServiceProvider`) exactly as they would a single transport.
class CallSignalingCoordinator {
  final CallSignalingService _pusher = CallSignalingService();
  final PollingCallSignalingService _polling = PollingCallSignalingService();

  CallTransport? _active;

  /// Broadcast event callbacks, bound by `CallStateNotifier._bindSignaling`.
  void Function(Map<String, dynamic> data)? onIncomingCall;
  void Function(Map<String, dynamic> data)? onOffer;
  void Function(Map<String, dynamic> data)? onAnswer;
  void Function(Map<String, dynamic> data)? onIceCandidate;
  void Function(Map<String, dynamic> data)? onCallAccepted;
  void Function(Map<String, dynamic> data)? onCallDeclined;
  void Function(Map<String, dynamic> data)? onCallEnded;

  /// Whether the active transport is the realtime socket (vs polling fallback).
  bool get usingRealtime => _active != null && _active!.name == 'pusher';

  /// Name of the active transport, for logging.
  String get activeName => _active?.name ?? 'none';

  Future<void> connect() async {
    if (_active != null) return;

    _wire(_pusher);
    try {
      await _pusher.connect();
    } catch (e) {
      _fallbackToPolling();
      return;
    }
    _active = _pusher;
  }

  void _fallbackToPolling() {
    _active = _polling;
    _wire(_polling);
    unawaited(_polling.connect());
  }

  Future<void> subscribeToConversation(String conversationId) async {
    if (_active == null) await connect();
    await _active?.subscribeToConversation(conversationId);
  }

  void unsubscribeFromConversation(String? conversationId) {
    _pusher.unsubscribeFromConversation(conversationId);
    _polling.unsubscribeFromConversation(conversationId);
  }

  Future<void> dispose() async {
    await _pusher.dispose();
    await _polling.dispose();
    _active = null;
  }

  void _wire(CallTransport transport) {
    transport.onIncomingCall = onIncomingCall;
    transport.onOffer = onOffer;
    transport.onAnswer = onAnswer;
    transport.onIceCandidate = onIceCandidate;
    transport.onCallAccepted = onCallAccepted;
    transport.onCallDeclined = onCallDeclined;
    transport.onCallEnded = onCallEnded;
  }
}