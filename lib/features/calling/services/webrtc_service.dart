import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Service that manages the WebRTC peer connection and audio streams.
///
/// This is the low-level WebRTC wrapper. It handles:
/// - Creating the peer connection
/// - Local audio capture
/// - Offer/answer exchange
/// - ICE candidate management (local candidates are surfaced via callback,
///   remote candidates are queued until the remote description is set)
/// - Mute/unmute and speakerphone


class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  List<Map<String, dynamic>> _iceServers = const [];
  bool _isRemoteDescriptionSet = false;
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  /// Callbacks registered by the app. They must be registered before the
  /// peer connection is created (i.e. before createOffer/createAnswer).
  void Function(RTCIceCandidate candidate)? onLocalIceCandidate;
  void Function(MediaStream stream)? onRemoteStream;
  void Function(RTCPeerConnectionState state)? onConnectionStateChanged;

  /// Initialize the service with ICE server configuration from the backend.
  ///
  /// Safe to call repeatedly; the local stream is only captured once (and
  /// re-captured after [dispose]).
  Future<void> initialize(List<Map<String, dynamic>> iceServers) async {
    _iceServers = iceServers;
    _localStream ??= await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
  }

  /// Create the peer connection (once) and attach the local stream.
  Future<void> _ensurePeerConnection() async {
    if (_peerConnection != null) return;

    final config = <String, dynamic>{
      'iceServers': _iceServers.map((server) => {
        'urls': server['urls'],
        if (server.containsKey('username')) 'username': server['username'],
        if (server.containsKey('credential')) 'credential': server['credential'],
      }).toList(),
    };

    final pc = await createPeerConnection(config);
    _peerConnection = pc;

    // Wire the callbacks registered by the app.
    pc.onIceCandidate = (candidate) => onLocalIceCandidate?.call(candidate);
    pc.onAddStream = (stream) => onRemoteStream?.call(stream);
    pc.onConnectionState = (state) => onConnectionStateChanged?.call(state);

    final localStream = _localStream;
    if (localStream != null) {
      for (final track in localStream.getTracks()) {
        await pc.addTrack(track, localStream);
      }
    }
  }

  /// Create an SDP offer to start the call.
  Future<Map<String, dynamic>> createOffer() async {
    await _ensurePeerConnection();

    final offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);

    return {'type': offer.type, 'sdp': offer.sdp};
  }

  /// Set the remote SDP offer and create an answer.
  Future<Map<String, dynamic>> createAnswer(Map<String, dynamic> offer) async {
    await _ensurePeerConnection();

    await setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer({});
    await _peerConnection!.setLocalDescription(answer);

    return {'type': answer.type, 'sdp': answer.sdp};
  }

  /// Set the remote SDP answer.
  Future<void> setRemoteAnswer(Map<String, dynamic> answer) =>
      setRemoteDescription(answer);

  /// Set a remote session description (offer or answer) and flush any
  /// ICE candidates that arrived before it was set.
  Future<void> setRemoteDescription(Map<String, dynamic> description) async {
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(description['sdp'], description['type']),
    );
    _isRemoteDescriptionSet = true;
    await _flushPendingCandidates();
  }

  /// Add a remote ICE candidate. Candidates that arrive before the remote
  /// description are queued and applied afterwards (adding a candidate
  /// before the remote description throws).
  Future<void> addIceCandidate(Map<String, dynamic> candidate) async {
    final rtcCandidate = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );

    if (!_isRemoteDescriptionSet) {
      _pendingRemoteCandidates.add(rtcCandidate);
      return;
    }

    await _peerConnection?.addCandidate(rtcCandidate);
  }

  Future<void> _flushPendingCandidates() async {
    if (_pendingRemoteCandidates.isEmpty) return;

    final queued = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();

    for (final candidate in queued) {
      await _peerConnection?.addCandidate(candidate);
    }
  }

  /// Toggle local audio mute.
  void toggleMute() {
    final localStream = _localStream;
    if (localStream != null) {
      for (final track in localStream.getAudioTracks()) {
        track.enabled = !track.enabled;
      }
    }
  }

  /// Check if local audio is muted.
  bool get isMuted {
    final localStream = _localStream;
    if (localStream != null) {
      for (final track in localStream.getAudioTracks()) {
        if (!track.enabled) return true;
      }
    }
    return false;
  }

  /// Set speakerphone on/off (mobile only).
  Future<void> setSpeakerphone(bool enabled) =>
      Helper.setSpeakerphoneOn(enabled);

  /// Dispose of all resources so the next call starts fresh.
  Future<void> dispose() async {
    _pendingRemoteCandidates.clear();
    _isRemoteDescriptionSet = false;
    await _localStream?.dispose();
    await _peerConnection?.close();
    _localStream = null;
    _peerConnection = null;
  }
}
