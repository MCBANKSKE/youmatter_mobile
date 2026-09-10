import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youmatter_mobile/core/networking/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiService();
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final notifications = await _api.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllNotificationsAsRead();
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark all as read')),
      );
    }
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    if (notification['read_at'] != null) return;
    try {
      await _api.markNotificationAsRead(notification['id'].toString());
      _load();
    } catch (_) {}
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_outline;
      case 'matching_attempt_created':
        return Icons.volunteer_activism_outlined;
      case 'conversation':
        return Icons.forum_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                                        separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification =
                          _notifications[index] as Map<String, dynamic>;
                      final data =
                          notification['data'] as Map<String, dynamic>?;
                      final isUnread = notification['read_at'] == null;
                      final createdAt = DateTime.tryParse(
                              notification['created_at']?.toString() ?? '') ??
                          DateTime.now();
                      final local = createdAt.toLocal();
                      final formatted =
                          '${local.day}/${local.month} '
                          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
                      return ListTile(
                        leading: Icon(
                          _iconFor(data?['type']?.toString() ??
                              notification['type']?.toString()),
                          color: isUnread
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                        title: Text(
                          data?['title']?.toString() ?? 'Notification',
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${data?['body']?.toString() ?? ''}\n$formatted',
                        ),
                        isThreeLine: true,
                        trailing: isUnread
                            ? Icon(
                                Icons.circle,
                                size: 10,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () => _markRead(notification),
                      );
                    },
                  ),
                ),
    );
  }
}