import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youmatter_mobile/features/messaging/services/conversation_timer_service.dart';

/// Widget displaying conversation countdown timer
class ConversationTimerWidget extends ConsumerWidget {
  const ConversationTimerWidget({
    super.key,
    required this.conversationId,
    required this.expiryTime,
    this.onExtend,
  });

  final int conversationId;
  final DateTime expiryTime;
  final VoidCallback? onExtend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerParams = ConversationTimerParams(
      conversationId: conversationId,
      expiryTime: expiryTime,
    );
    final timerState = ref.watch(conversationTimerProvider(timerParams));

    if (timerState.isExpired) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isWarning = timerState.isWarning;
    final isFinalWarning = timerState.remainingTime.inMinutes <= 5;

    Color progressColor;
    Color textColor;
    if (isFinalWarning) {
      progressColor = Colors.red;
      textColor = Colors.red;
    } else if (isWarning) {
      progressColor = Colors.orange;
      textColor = Colors.orange;
    } else {
      progressColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onSurface;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _calculateProgress(timerState.remainingTime),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: textColor),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(timerState.remainingTime),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isWarning) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.warning_amber_rounded, size: 16, color: textColor),
                  ],
                ],
              ),
              if (timerState.canExtend)
                TextButton.icon(
                  onPressed: onExtend,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    '+15 min (${timerState.extensionsUsed}/2)',
                    style: theme.textTheme.bodySmall,
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateProgress(Duration remainingTime) {
    const totalDuration = Duration(hours: 1);
    final elapsed = totalDuration - remainingTime;
    return (elapsed.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Compact timer widget for app bar
class ConversationTimerCompact extends ConsumerWidget {
  const ConversationTimerCompact({
    super.key,
    required this.conversationId,
    required this.expiryTime,
  });

  final int conversationId;
  final DateTime expiryTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerParams = ConversationTimerParams(
      conversationId: conversationId,
      expiryTime: expiryTime,
    );
    final timerState = ref.watch(conversationTimerProvider(timerParams));

    if (timerState.isExpired) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isWarning = timerState.isWarning;
    final isFinalWarning = timerState.remainingTime.inMinutes <= 5;

    Color textColor;
    if (isFinalWarning) {
      textColor = Colors.red;
    } else if (isWarning) {
      textColor = Colors.orange;
    } else {
      textColor = theme.colorScheme.onSurface;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          size: 14,
          color: textColor,
        ),
        const SizedBox(width: 4),
        Text(
          _formatTime(timerState.remainingTime),
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
