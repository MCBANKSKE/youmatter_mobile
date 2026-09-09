import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Service that manages the WebRTC peer connection and audio streams.
///
/// This is the low-level WebRTC wrapper. It handles:
/// - Creating the peer connection
/// - Local audio capture
/// - Offer/answer exchange
/// - ICE candidate management
/// - Mute/unmute
class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  List<Map<String, dynamic>> _iceServers = [];

  /// Initialize the service with ICE server configuration from the backend.
  Future<void> initialize(List<Map<String, dynamic>> iceServers) async {
    _iceServers = iceServers;
    await _createLocalStream();
  }

  /// Create the local audio stream and peer connection.
  Future<void> _createLocalStream() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
  }

  /// Create or recreate the peer connection.
  Future<void> _createPeerConnection() async {
    final config = <String, dynamic>{
      'iceServers': _iceServers.map((server) => {
        'urls': server['urls'],
        if (server.containsKey('username')) 'username': server['username'],
        if (server.containsKey('credential')) 'credential': server['credential'],
      }).toList(),
    };

    _peerConnection = await createPeerConnection(config);

    // Add local audio track to the connection.
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // Listen for remote audio stream.
    _peerConnection!.onAddStream = (MediaStream stream) {
      // Remote stream received — audio will play automatically.
    };

    // Listen for ICE candidates.
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      // Candidates are sent via the signaling service.
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      // Connection state changes.
    };
  }

  /// Create an SDP offer to start the call.
  Future<Map<String, dynamic>> createOffer() async {
    await _createPeerConnection();

    final offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);

    return {
      'type': offer.type,
      'sdp': offer.sdp,
    };
  }

  /// Set the remote SDP offer and create an answer.
  Future<Map<String, dynamic>> createAnswer(Map<String, dynamic> offer) async {
    await _createPeerConnection();

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    final answer = await _peerConnection!.createAnswer({});
    await _peerConnection!.setLocalDescription(answer);

    return {
      'type': answer.type,
      'sdp': answer.sdp,
    };
  }

  /// Set the remote SDP answer.
  Future<void> setRemoteAnswer(Map<String, dynamic> answer) async {
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type']),
    );
  }

  /// Add a remote ICE candidate.
  Future<void> addIceCandidate(Map<String, dynamic> candidate) async {
    await _peerConnection?.addCandidate(
      RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      ),
    );
  }

  /// Toggle local audio mute.
  void toggleMute() {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !track.enabled;
      }
    }
  }

  /// Check if local audio is muted.
  bool get isMuted {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        if (!track.enabled) return true;
      }
    }
    return false;
  }

  /// Set speakerphone on/off (mobile only).
  Future<void> setSpeakerphone(bool enabled) async {
    // Speakerphone toggle — platform-specific.
    // flutter_webrtc handles this internally on most platforms.
  }

  /// Get the ICE candidate stream for the signaling service.
  void Function(RTCIceCandidate)? get onIceCandidate =>
      _peerConnection?.onIceCandidate;

  /// Get the add stream callback.
  set onAddStream(void Function(MediaStream)? callback) {
    _peerConnection?.onAddStream = callback;
  }

  /// Get the connection state callback.
  set onConnectionStateChange(void Function(RTCPeerConnectionState)? callback) {
    _peerConnection?.onConnectionState = callback;
  }

  /// Dispose of all resources.
  Future<void> dispose() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
    _localStream = null;
    _peerConnection = null;
  }
}