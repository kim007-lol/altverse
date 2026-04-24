import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/services/api_service.dart';

import '../../../core/services/auth_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final role = authProv.role;

    try {
      final response = await ApiService.get('notifications?role=$role');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _notifications = data['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final role = authProv.role;

    try {
      final response = await ApiService.post('notifications/read-all', {
        'role': role,
      });
      if (response.statusCode == 200) {
        _fetchNotifications();
      }
    } catch (_) {}
  }

  Future<void> _markRead(String id, int index) async {
    try {
      final response = await ApiService.post('notifications/$id/read', {});
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _notifications[index]['is_read'] = 1; // Mark local as read
          });
        }
      }
    } catch (_) {}
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return timeago.format(date);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading || _notifications.isEmpty
                ? null
                : _markAllRead,
            child: Text(
              'Mark all read',
              style: TextStyle(color: theme.primaryColor, fontSize: 12),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Gagal memuat notifikasi'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _fetchNotifications,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, i) {
                final notif = _notifications[i];
                final isUnread =
                    notif['is_read'] == 0 || notif['is_read'] == false;
                final type = notif['type'] ?? 'default';

                return GestureDetector(
                  onTap: () {
                    if (isUnread) {
                      _markRead(notif['id'].toString(), i);
                    }
                    // TODO: Specific navigation based on notification type
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUnread
                          ? theme.primaryColor.withAlpha(10)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: isUnread
                          ? Border.all(color: theme.primaryColor.withAlpha(30))
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _notifColor(type).withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _notifIcon(type),
                            color: _notifColor(type),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['title'] ?? '',
                                style: TextStyle(
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              if (notif['body'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  notif['body'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(notif['created_at']),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'episode':
      case 'publish':
        return Icons.auto_stories;
      case 'follower':
      case 'follow':
        return Icons.person_add;
      case 'comment':
        return Icons.comment;
      case 'like':
        return Icons.favorite;
      case 'reward':
        return Icons.card_giftcard;
      case 'welcome':
      case 'gamification':
      case 'level_up':
      case 'achievement':
        return Icons.emoji_events;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _notifColor(String type) {
    switch (type) {
      case 'episode':
      case 'publish':
        return Colors.blue;
      case 'follower':
      case 'follow':
        return Colors.purple;
      case 'comment':
        return Colors.orange;
      case 'like':
        return Colors.red;
      case 'reward':
      case 'gamification':
      case 'level_up':
      case 'achievement':
        return Colors.green;
      case 'welcome':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
