import 'package:flutter/material.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';
import 'package:youmatter_mobile/features/calling/presentation/screens/outgoing_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<dynamic> _messages = [];
  Map<String, dynamic>? _conversation;
  String? _myUserId;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final me = await _api.getMe();
      final conversation =
          await _api.getConversation(widget.conversationId);
      final messages =
          await _api.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _myUserId = me['id'].toString();
        _conversation = conversation;
        // API returns newest-first; display oldest-first.
        _messages = messages.reversed.toList();
        _loading = false;
        _error = null;
      });
      _scrollToBottom();
      // Poll for new messages while the chat is open.
      await Future.delayed(const Duration(seconds: 3));
      if (mounted && (_conversation?['status'] == 'active')) _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load this conversation.';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  Future<void> _send() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await _api.sendMessage(widget.conversationId, body);
      _messageController.clear();
      if (!mounted) return;
      setState(() {
        _messages.add(message);
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send message')),
      );
    }
  }

  Future<void> _redact(Map<String, dynamic> message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove message?'),
        content:
            const Text('This message will be removed for both of you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.redactMessage(
        widget.conversationId,
        message['id'].toString(),
        'User deleted message',
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove message')),
      );
    }
  }

  Future<void> _end() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End conversation?'),
        content: const Text(
            'The conversation will be closed for both of you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.endConversation(widget.conversationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation ended')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not end conversation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _conversation?['status'] == 'active';
    final otherName = _getOtherName();
    return Scaffold(
      appBar: AppBar(
        title: Text(otherName),
        actions: [
          if (isActive)
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () => _startCall(otherName),
              tooltip: 'Voice call',
            ),
          if (isActive)
            TextButton(onPressed: _end, child: const Text('End')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              _messages[index] as Map<String, dynamic>;
                          final isMine =
                              message['sender_id'].toString() == _myUserId;
                          final isRedacted =
                              message['is_redacted'] == true;
                          return _MessageBubble(
                            message: message,
                            isMine: isMine,
                            isRedacted: isRedacted,
                            onLongPress:
                                (isMine && !isRedacted && isActive)
                                    ? () => _redact(message)
                                    : null,
                          );
                        },
                      ),
                    ),
                    if (isActive)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message…',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _send(),
                                ),
                              ),
                              IconButton(
                                onPressed: _sending ? null : _send,
                                icon: _sending
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.send),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Text(
                          'This conversation has ended.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
    );
  }

  /// Get the other participant's pseudonymous name.
  String _getOtherName() {
    if (_conversation == null || _myUserId == null) return 'Chat';
    final key = _conversation!['talker_id'].toString() == _myUserId
        ? 'listener'
        : 'talker';
    final other = _conversation![key] as Map<String, dynamic>?;
    final identity = other?['pseudonymous_identity'] as Map<String, dynamic>?;
    return (identity?['display_name'] ?? identity?['username'] ?? 'Anonymous')
        .toString();
  }

  /// Start a voice call with the other participant.
  Future<void> _startCall(String otherName) async {
    final conversationId = int.tryParse(widget.conversationId);
    if (conversationId == null) return;

    final otherId = _getOtherUserId();
    if (otherId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OutgoingCallScreen(
          conversationId: conversationId,
          remoteUserName: otherName,
        ),
      ),
    );
  }

  int? _getOtherUserId() {
    if (_conversation == null || _myUserId == null) return null;
    final key = _conversation!['talker_id'].toString() == _myUserId
        ? 'listener_id'
        : 'talker_id';
    final id = _conversation![key];
    return id is int ? id : int.tryParse(id.toString());
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMine;
  final bool isRedacted;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isRedacted,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isRedacted
                ? Colors.grey.shade300
                : isMine
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message['body'] ?? '',
            style: TextStyle(
              color: isRedacted
                  ? Colors.grey
                  : isMine
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
              fontStyle: isRedacted
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }
}
