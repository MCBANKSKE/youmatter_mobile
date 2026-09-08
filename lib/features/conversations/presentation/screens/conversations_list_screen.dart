import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final _api = ApiService();
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await _api.getMe();
      final conversations = await _api.getConversations();
      if (!mounted) return;
      setState(() {
        _myUserId = me['id'].toString();
        _conversations = conversations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _otherName(Map<String, dynamic> conversation) {
    final key = conversation['talker_id'].toString() == _myUserId
        ? 'listener'
        : 'talker';
    final other = conversation[key] as Map<String, dynamic>?;
    final identity =
        other?['pseudonymous_identity'] as Map<String, dynamic>?;
    return (identity?['display_name'] ?? identity?['username'] ?? 'Anonymous')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No conversations yet.\nStart one from the home screen.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conversation =
                          _conversations[index] as Map<String, dynamic>;
                      final isActive = conversation['status'] == 'active';
                      final latest = conversation['latest_message']
                          as Map<String, dynamic>?;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            _otherName(conversation)
                                .characters
                                .first
                                .toUpperCase(),
                          ),
                        ),
                        title: Text(_otherName(conversation)),
                        subtitle: Text(
                          latest?['body']?.toString() ??
                              (isActive
                                  ? 'Say hello 👋'
                                  : 'Conversation ended'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isActive
                            ? const Icon(Icons.circle,
                                size: 10, color: Colors.green)
                            : const Icon(Icons.check_circle_outline,
                                size: 18, color: Colors.grey),
                        onTap: () async {
                          await context
                              .push('/chat/${conversation['id']}')
                              .whenComplete(_load);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}