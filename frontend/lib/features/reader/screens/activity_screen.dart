import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

/// Reader Activity tab — shows reader-specific notifications
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await ApiService.get(
        '${ApiEndpoints.notifications}?role=reader',
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _notifications = (json['data'] ?? []) as List;
            _unreadCount = json['unread_count'] ?? 0;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_unreadCount > 0)
                        Text(
                          '$_unreadCount belum dibaca',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: _unreadCount > 0 ? _markAllRead : null,
                    child: Text(
                      'Tandai semua',
                      style: TextStyle(
                        fontSize: 12,
                        color: _unreadCount > 0
                            ? theme.primaryColor
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: _notifications.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 100),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.notifications_none,
                                        size: 64,
                                        color: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Belum ada aktivitas',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Notifikasi seperti balasan komentar,\nseries baru, dan pembelian akan muncul di sini.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: _notifications.length,
                              itemBuilder: (_, i) =>
                                  _buildNotifTile(_notifications[i], theme),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifTile(dynamic notif, ThemeData theme) {
    final isRead = notif['is_read'] == true;
    final type = notif['type'] ?? '';
    final icon = _notifIcon(type);
    final color = _notifColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? theme.cardColor : theme.primaryColor.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: isRead
            ? null
            : Border.all(color: theme.primaryColor.withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif['title'] ?? '',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (notif['body'] != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    notif['body'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _timeAgo(notif['created_at']),
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          if (!isRead)
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
    );
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.post(ApiEndpoints.notificationMarkAllRead, {
        'role': 'reader',
      });
      _fetch();
    } catch (_) {}
  }

  // ─── Reader notification types ───
  IconData _notifIcon(String type) => switch (type) {
    'comment_reply' => Icons.chat_bubble_outline,
    'new_episode' => Icons.auto_stories,
    'new_series' => Icons.library_books,
    'purchase_success' => Icons.check_circle,
    'follow_update' => Icons.person_add_alt_1,
    'system' => Icons.info_outline,
    _ => Icons.notifications_outlined,
  };

  Color _notifColor(String type) => switch (type) {
    'comment_reply' => Colors.teal,
    'new_episode' => Colors.blue,
    'new_series' => Colors.indigo,
    'purchase_success' => Colors.green,
    'follow_update' => Colors.purple,
    'system' => Colors.grey,
    _ => Colors.blueGrey,
  };

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
