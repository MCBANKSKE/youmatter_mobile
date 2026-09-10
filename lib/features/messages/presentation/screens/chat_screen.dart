import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';
import 'package:youmatter_mobile/features/calling/providers/call_state_provider.dart';

// ---------------------------------------------------------------------------
// Chat Screen
// ---------------------------------------------------------------------------

/// Conversation page for YouMatter.
///
/// Design goals (per the product spec):
/// - Calm, human, safe and extremely simple. The screen "disappears" and
///   lets two people talk.
/// - Pseudonymous identities only (never real names or emails).
/// - Voice calling is first-class: an in-header icon with a confirmation
///   step, surfaced via the global call overlay in main.dart.
/// - A contextual safety menu, never a permanently visible warning.
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
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
    _messageController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---- Loading / polling -------------------------------------------------

  Future<void> _load() async {
    try {
      // Keep the signaling socket warm and subscribed so incoming calls are
      // received while the chat is open. Await both so the subscription is
      // actually live before the user can place a call.
      await ref.read(callStateProvider.notifier).initialize();
      await ref
          .read(callSignalingServiceProvider)
          .subscribeToConversation(widget.conversationId);

      final me = await _api.getMe();
      final conversation = await _api.getConversation(widget.conversationId);
      final messages = await _api.getMessages(widget.conversationId);

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

      // Poll for new messages while the chat is open and active.
      await Future.delayed(const Duration(seconds: 3));
      if (mounted && (_conversation?['status'] == 'active')) {
        _load();
      }
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
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // ---- Messaging ---------------------------------------------------------

  Future<void> _send() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final message = await _api.sendMessage(widget.conversationId, body);
      _messageController.clear();
      if (!mounted) return;
      setState(() => _messages.add(message));
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send message.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _redact(Map<String, dynamic> message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove message?'),
        content: const Text('This message will be removed for both of you.'),
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
        const SnackBar(content: Text('Could not remove message.')),
      );
    }
  }

  Future<void> _end() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End conversation?'),
        content: const Text('The conversation will be closed for both of you.'),
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
      // The server has closed the conversation for both participants.
      // Drop the local state so the end-state screen shows immediately.
      setState(() {
        _conversation = null;
        _messages = [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not end conversation.')),
      );
    }
  }

  Future<void> _call() async {
    final conversationId = int.tryParse(widget.conversationId);
    if (conversationId == null) return;

    final otherId = _getOtherUserId();
    final otherName = _getOtherName();
    if (otherId == null) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call $otherName'),
        content: const Text(
          "Voice calls let you speak directly with the person you're "
          'talking with.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Call'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    // Ensure the signaling socket is connected and subscribed to the
    // conversation channel BEFORE placing the call.
    await ref.read(callStateProvider.notifier).initialize();
    await ref
        .read(callSignalingServiceProvider)
        .subscribeToConversation(widget.conversationId);

    ref.read(callStateProvider.notifier).startCall(
          conversationId: conversationId,
          remoteUserId: otherId,
          remoteUserName: otherName,
        );
  }

  void _showMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(0, 80, 0, 0),
      items: [
        const PopupMenuItem(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text('View profile'),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        PopupMenuItem(
          onTap: _call,
          child: const ListTile(
            leading: Icon(Icons.call_outlined),
            title: Text('Voice call'),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.notifications_off_outlined),
            title: Text('Mute notifications'),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.block_outlined),
            title: Text('Block'),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.report_outlined, color: Colors.orange),
            title: Text('Report'),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        PopupMenuItem(
          onTap: _end,
          child: const ListTile(
            leading: Icon(Icons.call_end_outlined, color: Colors.red),
            title: Text('End conversation'),
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }
// ---- Helpers -----------------------------------------------------------

  int? _getOtherUserId() {
    if (_conversation == null || _myUserId == null) return null;
    final key = _conversation!['talker_id'].toString() == _myUserId
        ? 'listener_id'
        : 'talker_id';
    final id = _conversation![key];
    return id is int ? id : int.tryParse(id.toString());
  }

  /// The other participant's pseudonymous identity.
  String _getOtherName() {
    if (_conversation == null || _myUserId == null) return 'Chat';
    final key = _conversation!['talker_id'].toString() == _myUserId
        ? 'listener'
        : 'talker';
    final other = _conversation![key] as Map<String, dynamic>?;
    final identity =
        other?['pseudonymous_identity'] as Map<String, dynamic>?;
    return (identity?['display_name'] ?? identity?['username'] ?? 'Anonymous')
        .toString();
  }

  /// Listener / Talker label for the header subtitle.
  String _getOtherRole() {
    if (_conversation == null || _myUserId == null) return '';
    final key = _conversation!['talker_id'].toString() == _myUserId
        ? 'listener'
        : 'talker';
    final other = _conversation![key] as Map<String, dynamic>?;
    final identity =
        other?['pseudonymous_identity'] as Map<String, dynamic>?;
    final role = identity?['role']?.toString() ?? '';
    return role.isNotEmpty
        ? role
        : (key == 'listener' ? 'Listener' : 'Talker');
  }

  bool get _isActive => _conversation?['status'] == 'active';
// ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherName = _getOtherName();

    return Scaffold(
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
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildChat(context, theme, otherName),
    );
  }

  Widget _buildChat(BuildContext context, ThemeData theme, String otherName) {
    final bool showStartBanner =
        _isActive && (_messages.isEmpty || _messages.length < 3);

    return Column(
      children: [
        // ---- Header ----
        Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 4),
                const CircleAvatar(child: Icon(Icons.person, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getOtherRole(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isActive) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.greenAccent[400],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Online',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.call_outlined),
                    onPressed: _call,
                    tooltip: 'Voice call',
                  ),
                ],
                const SizedBox(width: 4),
                if (_isActive)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: _showMenu,
                    tooltip: 'Menu',
                  ),
              ],
            ),
          ),
        ),

        // ---- Body ----
        Expanded(
          child: _isActive
              ? _buildConversation(context, theme, showStartBanner)
              : _buildEndState(context, theme),
        ),

        // ---- Composer (only while active) ----
        if (_isActive) _buildComposer(context, theme),
      ],
    );
  }
Widget _buildConversation(
    BuildContext context,
    ThemeData theme,
    bool showStartBanner,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      // Add one item for the start banner.
      itemCount: _messages.length + (showStartBanner ? 1 : 0),
      itemBuilder: (context, index) {
        if (showStartBanner && index == _messages.length) {
          return _ConversationStartBanner(theme: theme);
        }
        final message = _messages[index] as Map<String, dynamic>;
        final isMine = message['sender_id'].toString() == _myUserId;
        final isRedacted = message['is_redacted'] == true;

        // Show a sender name label when the speaker changes.
        bool isFirst = true;
        if (index > 0) {
          final prev = _messages[index - 1] as Map<String, dynamic>;
          isFirst =
              prev['sender_id'].toString() != message['sender_id'].toString();
        }

        return _MessageBubble(
          message: message,
          isMine: isMine,
          isRedacted: isRedacted,
          isFirst: isFirst,
          onLongPress: (isMine && !isRedacted && _isActive)
              ? () => _redact(message)
              : null,
        );
      },
    );
  }

  Widget _buildEndState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(child: Icon(Icons.person, size: 24)),
          const SizedBox(height: 16),
          Text(
            'Conversation ended',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Thank you for being here.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              Navigator.of(context)
                ..popUntil((route) => route.isFirst)
                ..maybePop();
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(BuildContext context, ThemeData theme) {
    final hasText = _messageController.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Attachment placeholder (+ for future media sharing).
            IconButton(
              icon: const Icon(Icons.add, size: 22),
              onPressed: () {},
              tooltip: 'Attach',
            ),
            const SizedBox(width: 4),
            // Text field.
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  filled: true,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  counterText: '',
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 4),
            // Mic / send toggle.
            if (_sending)
              const SizedBox(
                width: 36,
                height: 36,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              IconButton(
                icon: Icon(hasText ? Icons.send : Icons.mic_none),
                onPressed: hasText ? _send : () {},
                tooltip: hasText ? 'Send' : 'Voice message',
              ),
          ],
        ),
      ),
    );
  }
}
/// Small neutral banner shown at the start of an active conversation.
/// Disappears once the thread grows beyond a couple of messages.
class _ConversationStartBanner extends StatelessWidget {
  const _ConversationStartBanner({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedTime = DateFormat.jm().format(now);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Conversation started today at $formattedTime',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Render a single message bubble with a timestamp.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isRedacted,
    required this.isFirst,
    this.onLongPress,
  });

  final Map<String, dynamic> message;
  final bool isMine;
  final bool isRedacted;
  final bool isFirst;
  final VoidCallback? onLongPress;

  String _formatTime() {
    final createdAt = message['created_at'];
    if (createdAt == null) return '';
    final parsed = DateTime.tryParse(createdAt.toString());
    if (parsed == null) return '';
    return DateFormat.jm().format(parsed);
  }

  bool get _isRead => message['is_read'] == true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (isFirst && !isRedacted && !isMine)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              message['sender_name']?.toString() ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              color: isRedacted
                  ? Colors.grey.shade300
                  : isMine
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              isRedacted
                  ? 'This message was removed.'
                  : message['body'] ?? '',
              style: TextStyle(
                color: isRedacted
                    ? Colors.grey
                    : isMine
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                fontStyle:
                    isRedacted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              if (isMine) ...[
                const SizedBox(width: 4),
                Icon(
                  _isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: _isRead
                      ? Colors.blue
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
