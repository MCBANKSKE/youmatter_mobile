import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youmatter_mobile/features/calling/models/call_state.dart';
import 'package:youmatter_mobile/features/calling/providers/call_state_provider.dart';

/// Screen shown during an active voice call.
class ActiveCallScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final String remoteUserName;

  const ActiveCallScreen({
    super.key,
    required this.conversationId,
    required this.remoteUserName,
  });

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  Duration _callDuration = Duration.zero;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _callDuration = DateTime.now().difference(_startedAt!);
      });
      return true;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Text(
                'Stay safe â€” don\'t share personal information.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            const Spacer(),
            Text(
              callState.isActive ? 'â— Connected' : 'Connecting...',
              style: TextStyle(
                color: callState.isActive ? Colors.green : Colors.orange,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 60,
              child: Text(
                widget.remoteUserName.characters.first.toUpperCase(),
                style: const TextStyle(fontSize: 36),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.remoteUserName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Listener',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _formatDuration(_callDuration),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            _buildControls(context, callState),
            const SizedBox(height: 24),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'report') _showReportDialog();
                if (value == 'block') _showBlockDialog();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Report user'),
                ),
                const PopupMenuItem(value: 'block', child: Text('Block user')),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, CallState callState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            heroTag: 'mute',
            icon: callState.isMuted ? Icons.mic_off : Icons.mic,
            label: callState.isMuted ? 'Unmute' : 'Mute',
            isActive: callState.isMuted,
            onPressed: () => ref.read(callStateProvider.notifier).toggleMute(),
          ),
          _buildControlButton(
            heroTag: 'end',
            icon: Icons.call_end,
            label: 'End',
            isActive: false,
            activeColor: Colors.red,
            iconColor: Colors.white,
            onPressed: () => ref.read(callStateProvider.notifier).endCall(),
          ),
          _buildControlButton(
            heroTag: 'speaker',
            icon: callState.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            label: callState.isSpeakerOn ? 'Speaker On' : 'Speaker',
            isActive: callState.isSpeakerOn,
            onPressed: () =>
                ref.read(callStateProvider.notifier).toggleSpeaker(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String heroTag,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    Color? activeColor,
    Color? iconColor,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: heroTag,
          onPressed: onPressed,
          backgroundColor: isActive
              ? (activeColor ?? Theme.of(context).colorScheme.primary)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            icon,
            color:
                iconColor ??
                (isActive ? Theme.of(context).colorScheme.onPrimary : null),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report user'),
        content: const Text(
          'Are you sure you want to report this user? '
          'Our moderation team will review the conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block user'),
        content: const Text(
          'Are you sure you want to block this user? '
          'This will end the conversation and you won\'t be matched again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(callStateProvider.notifier).endCall();
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}
