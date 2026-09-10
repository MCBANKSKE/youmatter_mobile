// probe

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';
import 'package:youmatter_mobile/core/services/auth_service.dart';
import 'package:youmatter_mobile/features/calling/models/call_state.dart';
import 'package:youmatter_mobile/features/calling/services/call_signaling_coordinator.dart';
import 'package:youmatter_mobile/features/calling/services/conversation_expiry_service.dart';
import 'package:youmatter_mobile/features/calling/services/webrtc_service.dart';

/// Provider for the WebRTC service instance.
final webRTCServiceProvider = Provider<WebRTCService>((ref) {
  final service = WebRTCService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the call signaling coordinator (Pusher with polling fallback).
///
/// Consumers bind to these callbacks and call `subscribeToConversation` /
/// `unsubscribeFromConversation` as if it were a single transport; the
/// coordinator chooses the best transport automatically.
final callSignalingServiceProvider = Provider<CallSignalingCoordinator>((ref) {
  final coordinator = CallSignalingCoordinator();
  ref.onDispose(() => coordinator.dispose());
  return coordinator;
});

/// Provider for the conversation-expiry poller.
///
/// Conversations auto-end after 1 hour on the server, but the client may miss
/// the realtime event (backgrounded, queue worker down). This service polls
/// every 25 minutes and surfaces a `conversationEnded` callback so the UI /
/// active call can tear down promptly.
final conversationExpiryServiceProvider =
    Provider<ConversationExpiryService>((ref) {
  final service = ConversationExpiryService(ApiService());
  ref.onDispose(() => service.dispose());
  return service;
});

/// Deadline applied while ringing/connecting so failed or abandoned calls
/// do not leave the app stuck on a call screen.
const Duration _callTimeout = Duration(seconds: 45);

/// Provider for call state management.
class CallStateNotifier extends StateNotifier<CallState> {
  CallStateNotifier(this._ref) : super(const CallState()) { _bindSignaling(); }

  final Ref _ref;
  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>>? _iceServers;
  Map<String, dynamic>? _remoteOffer;
  bool _answerPending = false;
  bool _isInitialized = false;
  int? _cachedUserId;
  Timer? _callTimer;

  void _bindSignaling() {
    _ref.read(callSignalingServiceProvider)
      ..onIncomingCall = _onIncomingCall
      ..onOffer = _onOfferReceived
      ..onAnswer = _onAnswerReceived
      ..onIceCandidate = _onIceCandidateReceived
      ..onCallAccepted = _onCallAccepted
      ..onCallDeclined = _onCallDeclined
      ..onCallEnded = _onCallEndedRemote;

    // Server-side conversation expiry (1-hour auto-end) is the fallback for
    // missed realtime events. Tear down the call when the conversation ends.
    _ref.read(conversationExpiryServiceProvider).onConversationEnded =
        _onConversationEndedServer;
  }

  void _bindWebRtcCallbacks() {
    _ref.read(webRTCServiceProvider)
      ..onLocalIceCandidate = _sendLocalIceCandidate
      ..onConnectionStateChanged = _onPeerConnectionState;
  }

  /// Fetch ICE servers and open the signaling WebSocket (once).
  Future<void> initialize() async {
    if (!await _ensureInitialized()) return;
  }

  Future<bool> _ensureInitialized() async {
    if (_isInitialized) return true;
    try {
      _iceServers = await _api.getIceServers();
      await _ref.read(callSignalingServiceProvider).connect();
      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      state = state.copyWith(
        status: CallStatus.ended,
        errorMessage: 'Failed to initialize call: $e',
      );
      return false;
    }
  }

  Future<bool> _ensureWebRtcReady() async {
    if (!await _ensureInitialized()) return false;

    // Request permissions before accessing the microphone.
    final microphoneStatus = await Permission.microphone.request();
    if (!microphoneStatus.isGranted) {
      state = state.copyWith(
        status: CallStatus.ended,
        errorMessage: 'Microphone permission denied.',
      );
      return false;
    }

    final iceServers = _iceServers;
    if (iceServers == null) return false;
    try {
      await _ref.read(webRTCServiceProvider).initialize(iceServers);
      _bindWebRtcCallbacks();
      return true;
    } catch (e) {
      state = state.copyWith(
        status: CallStatus.ended,
        errorMessage: 'Microphone unavailable: $e',
      );
      return false;
    }
  }

  /// Start a call in a conversation.
  Future<void> startCall({
    required int conversationId,
    required int remoteUserId,
    required String remoteUserName,
  }) async {
    if (!_isIdle()) return;
    if (!await _ensureWebRtcReady()) return;

    // Set connecting state first so the UI shows the outgoing call screen
    state = CallState(
      status: CallStatus.connecting,
      conversationId: conversationId,
      remoteUserId: remoteUserId,
      remoteUserName: remoteUserName,
      isIncoming: false,
    );

    try {
      await _ref
          .read(callSignalingServiceProvider)
          .subscribeToConversation(conversationId.toString());

      // Start the conversation-expiry poll so the client notices when the
      // server ends the conversation (1-hour auto-end) even if the realtime
      // event is missed.
      _ref.read(conversationExpiryServiceProvider)
          .watchConversation(conversationId.toString());

      final call = await _api.startCall(conversationId);
      final callId = int.tryParse(call['id'].toString());
      if (callId == null) throw Exception('Call session id missing.');

      // Update state with callId and set to ringing
      state = state.copyWith(
        status: CallStatus.ringing,
        callId: callId,
      );

      final offer = await _ref.read(webRTCServiceProvider).createOffer();
      await _sendSignal(callId, {'event': 'offer', 'offer': offer});
      _startCallTimer();
    } catch (e) {
      // Only update error message, keep the state for the UI to show
      state = state.copyWith(
        status: CallStatus.ended,
        errorMessage: 'Failed to start call: $e',
      );
      // Don't teardown immediately - let the UI show the error
      Future.delayed(const Duration(seconds: 3), () {
        _teardownLocal();
      });
    }
  }

  Future<void> _onIncomingCall(Map<String, dynamic> data) async {
    final callId = int.tryParse(data['id'].toString());
    final conversationId = int.tryParse(data['conversation_id'].toString());
    final initiatedBy = int.tryParse(data['initiated_by'].toString());
    if (callId == null || conversationId == null) return;
    if (initiatedBy == await _currentUserId()) return;
    if (!_isIdle()) return;

    state = state.copyWith(
      status: CallStatus.ringing,
      callId: callId,
      conversationId: conversationId,
      remoteUserId: initiatedBy,
      remoteUserName: 'Anonymous',
      isIncoming: true,
    );

    await initialize();
    await _ref
        .read(callSignalingServiceProvider)
        .subscribeToConversation(conversationId.toString());
    await _loadCallerName(conversationId);
    _startCallTimer();
  }

  Future<void> _loadCallerName(int conversationId) async {
    try {
      final userId = (await _currentUserId()).toString();
      final conversation = await _api.getConversation(conversationId.toString());
      final key = conversation['talker_id'].toString() == userId
          ? 'listener'
          : 'talker';
      final other = conversation[key] as Map<String, dynamic>?;
      final identity = other?['pseudonymous_identity'] as Map<String, dynamic>?;
      final name =
          (identity?['display_name'] ?? identity?['username'] ?? 'Anonymous')
              .toString();
      if (state.status == CallStatus.ringing) {
        state = state.copyWith(remoteUserName: name);
      }
    } catch (e) {
      // Best-effort; a missing caller name should not break the call flow.
    }
  }

  Future<void> acceptCall() async {
    final callId = state.callId;
    if (callId == null || state.status != CallStatus.ringing) return;
    state = state.copyWith(status: CallStatus.connecting);
    final offer = _remoteOffer;
    if (offer == null) {
      _answerPending = true;
      return;
    } 
 await _createAndSendAnswer();
  }

  Future<void> _createAndSendAnswer() async {
    final callId = state.callId;
    final offer = _remoteOffer;
    if (callId == null || offer == null) return;
    try {
      if (!await _ensureWebRtcReady()) return;
      final answer =
          await _ref.read(webRTCServiceProvider).createAnswer(offer);
      await _sendSignal(callId, {'event': 'answer', 'answer': answer});
      await _api.acceptCall(callId);
    } catch (e) {
      state = state.copyWith(
        status: CallStatus.ended,
        errorMessage: 'Failed to accept call: $e',
      );
      await _teardownLocal();
    }
  }

  Future<void> _onOfferReceived(Map<String, dynamic> data) async {
    final fromUserId = int.tryParse(data['from_user_id'].toString());
    if (fromUserId == await _currentUserId()) return;
    final status = state.status;
    if (status != CallStatus.ringing && status != CallStatus.connecting) return;
    final offer = data['offer'];
    if (offer is! Map<String, dynamic>) return;
    _remoteOffer = {'sdp': offer['sdp'], 'type': offer['type']};
    if (state.status == CallStatus.connecting && _answerPending) {
      _answerPending = false;
      await _createAndSendAnswer();
    }
  }

  Future<void> _onAnswerReceived(Map<String, dynamic> data) async {
    final fromUserId = int.tryParse(data['from_user_id'].toString());
    if (fromUserId == await _currentUserId()) return;
    if (state.status == CallStatus.idle || state.status == CallStatus.ended) return;
    final answer = data['answer'];
    if (answer is! Map<String, dynamic>) return;
    await _ref.read(webRTCServiceProvider).setRemoteAnswer(answer);
    _clearCallTimer();
    state = state.copyWith(status: CallStatus.connecting);
  }

  Future<void> _onIceCandidateReceived(Map<String, dynamic> data) async {
    final fromUserId = int.tryParse(data['from_user_id'].toString());
    if (fromUserId == await _currentUserId()) return;
    final candidate = data['candidate'];
    if (candidate is! Map<String, dynamic>) return;
    await _ref.read(webRTCServiceProvider).addIceCandidate(candidate);
  }

  Future<void> _sendLocalIceCandidate(RTCIceCandidate candidate) async {
    final callId = state.callId;
    if (callId == null) return;
    await _sendSignal(callId, {
      'event': 'ice',
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
    });
  }

  void _onCallAccepted(Map<String, dynamic> data) {
    if (state.status == CallStatus.ringing) {
      _clearCallTimer();
      state = state.copyWith(status: CallStatus.connecting);
    }
  }

  void _onCallDeclined(Map<String, dynamic> data) {
    if (state.status == CallStatus.idle) return;
    _teardownLocal();
  }

  void _onCallEndedRemote(Map<String, dynamic> data) {
    if (state.status == CallStatus.idle) return;
    _teardownLocal();
  }

  /// Fired by the ConversationExpiryService when the server reports the
  /// conversation has ended (e.g. after the 1-hour window). Tear down the
  /// active call so the user is not left on a dead WebRTC session.
  void _onConversationEndedServer(Map<String, dynamic> status) {
    if (state.status == CallStatus.idle) return;
    _teardownLocal();
  }

  Future<void> _sendSignal(int callId, Map<String, dynamic> body) async {
    try {
      await _api.sendSignal(callId, body);
    } catch (e) {
      // The call will surface a connection error via the call timer; do not
      // spam the user with signal-relay failures.
    }
  }

  void _startCallTimer() {
    _clearCallTimer();
    _callTimer = Timer(_callTimeout, () async {
      final s = state.status;
      if (s == CallStatus.ringing || s == CallStatus.connecting) {
        if (state.isIncoming) {
          await declineCall();
        } else {
          await endCall();
        }
      }
    });
  }

  void _clearCallTimer() { _callTimer?.cancel(); _callTimer = null; }

  Future<void> endCall() async {
    final callId = state.callId;
    try {
      if (callId != null) await _api.endCall(callId);
    } catch (e) {
      // Proceed with local teardown even if the server request fails.
    }
    await _teardownLocal();
  }

  Future<void> declineCall() async {
    final callId = state.callId;
    try {
      if (callId != null) await _api.declineCall(callId);
    } catch (e) {
      // Proceed with local teardown even if the server request fails.
    }
    await _teardownLocal();
  }

  Future<void> _teardownLocal() async {
    _clearCallTimer();
    _remoteOffer = null;
    _answerPending = false;
    await _ref.read(webRTCServiceProvider).dispose();
    _ref.read(callSignalingServiceProvider).unsubscribeFromConversation(
      state.conversationId?.toString(),
    );
    _ref.read(conversationExpiryServiceProvider).stopWatching();
    state = const CallState();
  }

  void toggleMute() {
    final webrtc = _ref.read(webRTCServiceProvider);
    webrtc.toggleMute();
    state = state.copyWith(isMuted: webrtc.isMuted);
  }

  void toggleSpeaker() {
    state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
    unawaited(_ref.read(webRTCServiceProvider).setSpeakerphone(state.isSpeakerOn));
  }

  void handleIncomingCall({
    required int callId,
    required int conversationId,
    required int remoteUserId,
    required String remoteUserName,
  }) {
    if (_isBusy()) return;
    _ref
        .read(callSignalingServiceProvider)
        .subscribeToConversation(conversationId.toString());
    state = CallState(
      status: CallStatus.ringing,
      callId: callId,
      conversationId: conversationId,
      remoteUserId: remoteUserId,
      remoteUserName: remoteUserName,
      isIncoming: true,
    );
    _startCallTimer();
  }

  bool _isIdle() => state.status == CallStatus.idle || state.status == CallStatus.ended;
  bool _isBusy() => ! _isIdle();

  void reset() {
    _clearCallTimer();
    _remoteOffer = null;
    _answerPending = false;
    state = const CallState();
  }

  Future<int> _currentUserId() async {
    final cached = _cachedUserId;
    if (cached != null) return cached;
    final user = await _authService.getUserData();
    final id = int.tryParse(user?['id'].toString() ?? '') ?? 0;
    _cachedUserId = id;
    return id;
  }

  void _onPeerConnectionState(RTCPeerConnectionState peerState) {
    if (peerState == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      _clearCallTimer();
      if (state.status != CallStatus.idle) {
        state = state.copyWith(
          status: CallStatus.active,
          startedAt: state.startedAt ?? DateTime.now(),
        );
      }
    } else if (peerState ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        peerState == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      if (state.status == CallStatus.active ||
          state.status == CallStatus.connecting) {
        state = state.copyWith(
          status: CallStatus.ended,
          errorMessage: 'Call connection lost.',
        );
      }
    }
  }
}

/// The main call state provider.
final callStateProvider = StateNotifierProvider<CallStateNotifier, CallState>(
  (ref) => CallStateNotifier(ref),
);