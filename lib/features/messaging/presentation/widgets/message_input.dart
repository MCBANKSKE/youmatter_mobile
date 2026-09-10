import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youmatter_mobile/features/messages/services/voice_message_service.dart';

/// Provider for the audio recording service
final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  final service = AudioRecordingService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Message input widget with text and audio recording capabilities
class MessageInput extends ConsumerStatefulWidget {
  final int conversationId;
  final String? conversationType;
  final void Function(String message, {String? audioPath}) onSendMessage;

  const MessageInput({
    super.key,
    required this.conversationId,
    required this.onSendMessage,
    this.conversationType,
  });

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;
  bool _isRecordingAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkRecordingAvailability();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkRecordingAvailability() async {
    final audioService = ref.read(audioRecordingServiceProvider);
    final available = await audioService.isAvailable();
    if (mounted) {
      setState(() {
        _isRecordingAvailable = available;
      });
    }
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    widget.onSendMessage(text);
    _textController.clear();
    _focusNode.requestFocus();
  }

  Future<void> _startRecording() async {
    final audioService = ref.read(audioRecordingServiceProvider);
    final path = await audioService.startRecording();

    if (path != null && mounted) {
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    final audioService = ref.read(audioRecordingServiceProvider);
    final recorded = await audioService.stopRecording();

    if (mounted) {
      setState(() {
        _isRecording = false;
      });
    }

    if (recorded != null) {
      widget.onSendMessage('[Audio message]', audioPath: recorded.path);
    }
  }

  Future<void> _cancelRecording() async {
    final audioService = ref.read(audioRecordingServiceProvider);
    await audioService.cancelRecording();

    if (mounted) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: _isRecording ? _buildRecordingUI(theme) : _buildInputUI(theme),
      ),
    );
  }

  Widget _buildInputUI(ThemeData theme) {
    return Row(
      children: [
        // Audio record button
        if (_isRecordingAvailable)
          IconButton(
            icon: Icon(
              Icons.mic,
              color: theme.colorScheme.primary,
            ),
            onPressed: _startRecording,
            tooltip: 'Record audio message',
          ),
        // Text input field
        Expanded(
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Type a message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendTextMessage(),
          ),
        ),
        const SizedBox(width: 8),
        // Send button
        IconButton(
          icon: Icon(
            Icons.send,
            color: theme.colorScheme.primary,
          ),
          onPressed: _textController.text.trim().isEmpty ? null : _sendTextMessage,
          tooltip: 'Send message',
        ),
      ],
    );
  }

  Widget _buildRecordingUI(ThemeData theme) {
    return Row(
      children: [
        // Cancel button
        IconButton(
          icon: Icon(
            Icons.delete,
            color: Colors.red,
          ),
          onPressed: _cancelRecording,
          tooltip: 'Cancel recording',
        ),
        // Recording indicator
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                // Pulsing red dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Recording...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                // Recording duration
                _RecordingDuration(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Stop/Send button
        IconButton(
          icon: Icon(
            Icons.send,
            color: theme.colorScheme.primary,
          ),
          onPressed: _stopRecording,
          tooltip: 'Send audio message',
        ),
      ],
    );
  }
}

/// Widget to display recording duration
class _RecordingDuration extends StatefulWidget {
  @override
  State<_RecordingDuration> createState() => _RecordingDurationState();
}

class _RecordingDurationState extends State<_RecordingDuration> {
  Duration _duration = Duration.zero;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _updateDuration();
  }

  void _updateDuration() {
    if (!mounted) return;

    setState(() {
      _duration = DateTime.now().difference(_startTime);
    });

    Future.delayed(const Duration(seconds: 1), _updateDuration);
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (_duration.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$minutes:$seconds',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}
