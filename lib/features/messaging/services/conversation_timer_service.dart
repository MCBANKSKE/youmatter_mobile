import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

/// State for the conversation timer
class ConversationTimerState {
  const ConversationTimerState({
    required this.remainingTime,
    required this.isWarning,
    this.canExtend = false,
    this.extensionsUsed = 0,
    this.isExpired = false,
  });

  final Duration remainingTime;
  final bool isWarning;
  final bool canExtend;
  final int extensionsUsed;
  final bool isExpired;

  ConversationTimerState copyWith({
    Duration? remainingTime,
    bool? isWarning,
    bool? canExtend,
    int? extensionsUsed,
    bool? isExpired,
  }) {
    return ConversationTimerState(
      remainingTime: remainingTime ?? this.remainingTime,
      isWarning: isWarning ?? this.isWarning,
      canExtend: canExtend ?? this.canExtend,
      extensionsUsed: extensionsUsed ?? this.extensionsUsed,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}

/// Service for managing conversation auto-expiry timer
class ConversationTimerService extends StateNotifier<ConversationTimerState> {
  ConversationTimerService({
    required this.conversationId,
    required this.expiryTime,
    this.onExpired,
    this.onWarning,
  }) : super(ConversationTimerState(
          remainingTime: expiryTime.difference(DateTime.now()),
          isWarning: false,
          canExtend: false,
          extensionsUsed: 0,
          isExpired: false,
        )) {
    _startTimer();
  }

  final int conversationId;
  DateTime expiryTime;
  final VoidCallback? onExpired;
  final VoidCallback? onWarning;

  Timer? _timer;
  bool _warningTriggered = false;
  bool _finalWarningTriggered = false;

  // Configuration
  static const Duration _warningThreshold = Duration(minutes: 10);
  static const Duration _finalWarningThreshold = Duration(minutes: 5);
  static const Duration _extensionDuration = Duration(minutes: 15);
  static const int _maxExtensions = 2;

  /// Start the countdown timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
    _updateTimer(); // Initial update
  }

  /// Update the timer state
  void _updateTimer() {
    final now = DateTime.now();
    final remaining = expiryTime.difference(now);

    // Check if expired
    if (remaining.isNegative || remaining == Duration.zero) {
      state = state.copyWith(
        remainingTime: Duration.zero,
        isExpired: true,
        isWarning: true,
      );
      _timer?.cancel();
      onExpired?.call();
      return;
    }

    // Check warning thresholds
    if (remaining <= _finalWarningThreshold && !_finalWarningTriggered) {
      _finalWarningTriggered = true;
      onWarning?.call();
    } else if (remaining <= _warningThreshold && !_warningTriggered) {
      _warningTriggered = true;
      onWarning?.call();
    }

    // Check if extension is available (only when < 10 minutes and < max extensions)
    final canExtend = remaining <= _warningThreshold &&
        state.extensionsUsed < _maxExtensions;

    state = state.copyWith(
      remainingTime: remaining,
      isWarning: remaining <= _warningThreshold,
      canExtend: canExtend,
    );
  }

  /// Extend the conversation by 15 minutes
  Future<bool> extendConversation() async {
    if (!state.canExtend || state.extensionsUsed >= _maxExtensions) {
      return false;
    }

    // Calculate new expiry time
    final now = DateTime.now();
    final currentRemaining = expiryTime.difference(now);
    final newRemaining = currentRemaining + _extensionDuration;
    expiryTime = now.add(newRemaining);

    // Reset warning triggers
    _warningTriggered = false;
    _finalWarningTriggered = false;

    // Update state
    state = state.copyWith(
      remainingTime: newRemaining,
      isWarning: false,
      canExtend: state.extensionsUsed + 1 < _maxExtensions,
      extensionsUsed: state.extensionsUsed + 1,
      isExpired: false,
    );

    // Restart timer
    _startTimer();

    return true;
  }

  /// Get formatted remaining time string (MM:SS)
  String get formattedTime {
    final minutes = state.remainingTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (state.remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Get remaining time as a percentage (0.0 to 1.0)
  double get progressPercentage {
    const totalDuration = Duration(hours: 1);
    final elapsed = totalDuration - state.remainingTime;
    return (elapsed.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for conversation timer
final conversationTimerProvider = StateNotifierProvider.family<
    ConversationTimerService, ConversationTimerState, ConversationTimerParams>(
  (ref, params) {
    return ConversationTimerService(
      conversationId: params.conversationId,
      expiryTime: params.expiryTime,
      onExpired: params.onExpired,
      onWarning: params.onWarning,
    );
  },
);

/// Parameters for conversation timer provider
class ConversationTimerParams {
  const ConversationTimerParams({
    required this.conversationId,
    required this.expiryTime,
    this.onExpired,
    this.onWarning,
  });

  final int conversationId;
  final DateTime expiryTime;
  final VoidCallback? onExpired;
  final VoidCallback? onWarning;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationTimerParams &&
          runtimeType == other.runtimeType &&
          conversationId == other.conversationId &&
          expiryTime == other.expiryTime;

  @override
  int get hashCode => conversationId.hashCode ^ expiryTime.hashCode;
}
