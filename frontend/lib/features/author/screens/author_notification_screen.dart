import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

/// Author Notification Screen — shows author-specific notifications
/// (episode unlocks, tips, new followers, tier ups, badge earned)
class AuthorNotificationScreen extends StatefulWidget {
  const AuthorNotificationScreen({super.key});

  @override
  State<AuthorNotificationScreen> createState() =>
      _AuthorNotificationScreenState();
}

class _AuthorNotificationScreenState extends State<AuthorNotificationScreen> {
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
        '${ApiEndpoints.notifications}?role=author',
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
      appBar: AppBar(
        title: const Text('Notifikasi Author'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Tandai semua',
                style: TextStyle(fontSize: 12, color: theme.primaryColor),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: _notifications.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.campaign_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada notifikasi',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Saat readers unlock episode,\ntip, atau follow kamu — muncul di sini.',
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
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Unread Banner ───
                        if (_unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mark_email_unread,
                                  size: 18,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$_unreadCount notifikasi baru',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // ─── Notification List ───
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _notifications.length,
                            itemBuilder: (_, i) =>
                                _buildNotifTile(_notifications[i], theme),
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
        color: isRead ? theme.cardColor : color.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: isRead ? null : Border.all(color: color.withAlpha(40)),
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
                Row(
                  children: [
                    _TypeBadge(type: type),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(notif['created_at']),
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.post(ApiEndpoints.notificationMarkAllRead, {
        'role': 'author',
      });
      _fetch();
    } catch (_) {}
  }

  // ─── Author notification types ───
  IconData _notifIcon(String type) => switch (type) {
    'episode_unlock' => Icons.lock_open_rounded,
    'tip_received' => Icons.monetization_on_rounded,
    'new_follower' => Icons.person_add_rounded,
    'comment_reply' => Icons.chat_bubble_rounded,
    'badge_earned' => Icons.emoji_events_rounded,
    'tier_up' => Icons.diamond_rounded,
    'daily_reward' => Icons.card_giftcard_rounded,
    'milestone' => Icons.flag_rounded,
    _ => Icons.campaign_rounded,
  };

  Color _notifColor(String type) => switch (type) {
    'episode_unlock' => Colors.orange,
    'tip_received' => Colors.pink,
    'new_follower' => Colors.purple,
    'comment_reply' => Colors.teal,
    'badge_earned' => Colors.amber.shade700,
    'tier_up' => Colors.blue,
    'daily_reward' => Colors.green,
    'milestone' => Colors.deepOrange,
    _ => Colors.grey,
  };

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
      if (diff.inHours < 24) return '${diff.inHours}j lalu';
      if (diff.inDays < 7) return '${diff.inDays}h lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─── Small type badge ───
class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  IconData get icon => switch (type) {
    'episode_unlock' => Icons.lock_open,
    'tip_received' => Icons.monetization_on,
    'new_follower' => Icons.person_add,
    'comment_reply' => Icons.chat_bubble,
    'badge_earned' => Icons.military_tech,
    'tier_up' => Icons.upgrade,
    'daily_reward' => Icons.card_giftcard,
    'milestone' => Icons.flag,
    _ => Icons.info,
  };

  String get label => switch (type) {
    'episode_unlock' => 'Unlock',
    'tip_received' => 'Tip',
    'new_follower' => 'Follower',
    'comment_reply' => 'Komentar',
    'badge_earned' => 'Badge',
    'tier_up' => 'Tier',
    'daily_reward' => 'Reward',
    'milestone' => 'Milestone',
    _ => 'Info',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
