import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:youmatter_mobile/features/calling/models/call_state.dart';
import 'package:youmatter_mobile/features/calling/services/webrtc_service.dart';
import 'package:youmatter_mobile/features/calling/services/call_signaling_service.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';
import 'package:youmatter_mobile/core/services/auth_service.dart';

/// Provider for the WebRTC service instance.
final webRTCServiceProvider = Provider<WebRTCService>((ref) {
  final service = WebRTCService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the call signaling service.
final callSignalingServiceProvider = Provider<CallSignalingService>((ref) {
  return CallSignalingService();
});

/// Provider for call state management.
class CallStateNotifier extends StateNotifier<CallState> {
  CallStateNotifier(this._ref) : super(const CallState());

  final Ref _ref;
  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();

  /// Initialize ICE servers and signaling.
  Future<void> initialize() async {
    try {
      final iceServers = await _api.getIceServers();
      final webrtc = _ref.read(webRTCServiceProvider);
      await webrtc.initialize(iceServers);

      final signaling = _ref.read(callSignalingServiceProvider);
      await signaling.connect();
    } catch (e) {
      state = state.copyWith(
        status: CallStatus.ended,
        errorMessage: 'Failed to initialize call: $e',
      );
    }
  }

  /// Start a call in a conversation.
  Future<void> startCall({
    required int conversationId,
    required int remoteUserId,
    required String remoteUserName,
  }) async {
    try {
      state = state.copyWith(
        status: CallStatus.ringing,
        conversationId: conversationId,
        remoteUserId: remoteUserId,
        remoteUserName: remoteUserName,
      );

      // Subscribe to conversation channel for signaling.
      final signaling = _ref.read(callSignalingServiceProvider);
      signaling.subscribeToConversation(conversationId.toString());

      // Create WebRTC offer.
      final webrtc = _ref.read(webRTCServiceProvider);
      final offer = await webrtc.createOffer();

      // Send offer via signaling.
      signaling.sendOffer(
        conversationId: conversationId,
        offer: offer,
        fromUserId: await _getCurrentUserId(),
      );

      // Notify backend.
      final call = await _api.startCall(conversationId);
      state = state.copyWith(callId: call['id'], status: CallStatus.connecting);
    } catch (e) {
      state = state.copyWith(
        status: CallStatus.ended,
        errorMessage: 'Failed to start call: $e',
      );
    }
  }

  /// Accept an incoming call.
  Future<void> acceptCall() async {
    try {
      state = state.copyWith(status: CallStatus.connecting);

      // Create answer (offer should have been received via signaling).
      // For now, we'll handle this when the offer arrives.

      // Notify backend.
      if (state.callId != null) {
        await _api.acceptCall(state.callId!);
      }

      state = state.copyWith(status: CallStatus.active);
    } catch (e) {
      state = state.copyWith(
        status: CallStatus.ended,
        errorMessage: 'Failed to accept call: $e',
      );
    }
  }

  /// Decline an incoming call.
  Future<void> declineCall() async {
    try {
      if (state.callId != null) {
        await _api.declineCall(state.callId!);
      }
    } catch (e) {
      // Ignore errors when declining.
    } finally {
      state = const CallState();
    }
  }

  /// End the current call.
  Future<void> endCall() async {
    try {
      if (state.callId != null) {
        await _api.endCall(state.callId!);
      }
    } catch (e) {
      // Ignore errors when ending.
    } finally {
      await _ref.read(webRTCServiceProvider).dispose();
      state = const CallState();
    }
  }

  /// Toggle mute.
  void toggleMute() {
    _ref.read(webRTCServiceProvider).toggleMute();
    state = state.copyWith(isMuted: !state.isMuted);
  }

  /// Toggle speaker.
  void toggleSpeaker() {
    state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
    _ref.read(webRTCServiceProvider).setSpeakerphone(state.isSpeakerOn);
  }

  /// Handle incoming call notification.
  void handleIncomingCall({
    required int callId,
    required int conversationId,
    required int remoteUserId,
    required String remoteUserName,
  }) {
    state = CallState(
      status: CallStatus.ringing,
      callId: callId,
      conversationId: conversationId,
      remoteUserId: remoteUserId,
      remoteUserName: remoteUserName,
    );
  }

  /// Reset call state.
  void reset() {
    state = const CallState();
  }

  Future<int> _getCurrentUserId() async {
    final user = await _authService.getUserData();
    return int.parse(user?['id'].toString() ?? '0');
  }
}

/// The main call state provider.
final callStateProvider = StateNotifierProvider<CallStateNotifier, CallState>((
  ref,
) {
  return CallStateNotifier(ref);
});
