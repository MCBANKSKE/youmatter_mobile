/// Represents the current state of a voice call.
enum CallStatus {
  idle,
  ringing,
  connecting,
  active,
  ended,
}

/// Immutable state for the call feature.
class CallState {
  const CallState({
    this.status = CallStatus.idle,
    this.callId,
    this.conversationId,
    this.remoteUserId,
    this.remoteUserName,
           this.isMuted = false,
    this.isSpeakerOn = false,
    this.isIncoming = false,
    this.startedAt,
    this.errorMessage,
  });

  final CallStatus status;
  final int? callId;
  final int? conversationId;
  final int? remoteUserId;
  final String? remoteUserName;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isIncoming;
  final DateTime? startedAt;
  final String? errorMessage;

  bool get isActive => status == CallStatus.active;
  bool get isRinging => status == CallStatus.ringing;
  bool get isConnecting => status == CallStatus.connecting;

  CallState copyWith({
    CallStatus? status,
    int? callId,
    int? conversationId,
    int? remoteUserId,
    String? remoteUserName,
        bool? isMuted,
    bool? isSpeakerOn,
    bool? isIncoming,
    DateTime? startedAt,
    String? errorMessage,
  }) {
    return CallState(
      status: status ?? this.status,
      callId: callId ?? this.callId,
      conversationId: conversationId ?? this.conversationId,
      remoteUserId: remoteUserId ?? this.remoteUserId,
      remoteUserName: remoteUserName ?? this.remoteUserName,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isIncoming: isIncoming ?? this.isIncoming,
      startedAt: startedAt ?? this.startedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}