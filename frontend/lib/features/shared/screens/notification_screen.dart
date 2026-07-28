import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../shared/providers/notification_provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../reader/screens/series_detail_screen.dart';
import '../../reader/screens/reader_profile_screen.dart';

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
      if (response.success) {
        final data = response.data;
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
      final response = await ApiService.post('notifications/read-all', body: {
        'role': role,
      });
      if (response.success) {
        if (mounted) {
          context.read<NotificationProvider>().clearUnreadCount();
        }
        _fetchNotifications();
      }
    } catch (_) {}
  }

  Future<void> _markRead(String id, int index) async {
    try {
      final response = await ApiService.post('notifications/$id/read', body: {});
      if (response.success) {
        if (mounted) {
          setState(() {
            _notifications[index]['is_read'] = true; // backend serializes is_read as bool
          });
          context.read<NotificationProvider>().decrementUnreadCount();
        }
      }
    } catch (_) {}
  }

  // Navigate to the relevant in-app screen based on the notification type.
  // The backend stores a `data` JSONB field on each notification — we read
  // entity IDs from it so we never navigate blindly.
  void _navigateFromNotif(Map<String, dynamic> notif) {
    final type = notif['type'] as String? ?? '';
    final data = (notif['data'] is Map<String, dynamic>)
        ? notif['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final seriesId = data['series_id'];
    final userId = data['user_id'] ?? data['follower_id'];

    switch (type) {
      case 'new_episode':
      case 'series_like':
        if (seriesId != null) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => SeriesDetailScreen(seriesId: seriesId is int ? seriesId : int.tryParse(seriesId.toString()) ?? 0)));
        }
        break;
      case 'new_follower':
        if (userId != null) {
          final uid = userId is int ? userId : int.tryParse(userId.toString()) ?? 0;
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ReaderProfileScreen(userId: uid)));
        }
        break;
      case 'tip_received':
        // Tip comes from a reader — show their profile if we have it.
        if (userId != null) {
          final uid = userId is int ? userId : int.tryParse(userId.toString()) ?? 0;
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ReaderProfileScreen(userId: uid)));
        }
        break;
      case 'new_comment':
      case 'comment_reply':
      case 'comment_like':
      case 'episode_like':
      case 'episode_unlock':
        if (seriesId != null) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => SeriesDetailScreen(seriesId: seriesId is int ? seriesId : int.tryParse(seriesId.toString()) ?? 0)));
        }
        break;
      default:
        // badge_earned, level_up, mission_complete, daily_reward — no deep link needed.
        break;
    }
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

  Future<void> _cleanupNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bersihkan Notifikasi?'),
        content: const Text('Notifikasi yang sudah dibaca (lebih dari 7 hari) akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await ApiService.delete(ApiEndpoints.notificationCleanup);
      if (res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi lama berhasil dibersihkan')));
        _fetchNotifications();
      }
    } catch (_) {}
  }

  Future<void> _showPreferences() async {
    Map<String, bool> prefs = {};
    try {
      final res = await ApiService.get(ApiEndpoints.notificationPreferences);
      if (res.success) {
        final data = res.data['data'] ?? res.data;
        if (data is Map) {
          data.forEach((k, v) {
            if (v is bool) prefs[k.toString()] = v;
          });
        }
      }
    } catch (_) {}

    if (!mounted) return;

    final labels = {
      'tips': 'Tips dari reader',
      'follows': 'Follower baru',
      'unlocks': 'Episode di-unlock',
      'comments': 'Komentar baru',
      'system': 'Sistem & update',
      'withdrawals': 'Status penarikan',
    };

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Pengaturan Notifikasi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: labels.entries.map((entry) {
                return SwitchListTile(
                  dense: true,
                  title: Text(entry.value, style: const TextStyle(fontSize: 14)),
                  value: prefs[entry.key] ?? true,
                  onChanged: (val) {
                    setDialogState(() => prefs[entry.key] = val);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.put(ApiEndpoints.notificationPreferences, body: prefs.map((k, v) => MapEntry(k, v)));
                } catch (_) {}
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'read_all') _markAllRead();
              if (val == 'cleanup') _cleanupNotifications();
              if (val == 'prefs') _showPreferences();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'read_all', child: Text('Tandai semua dibaca')),
              const PopupMenuItem(value: 'cleanup', child: Text('Bersihkan notifikasi lama')),
              const PopupMenuItem(value: 'prefs', child: Text('Pengaturan notifikasi')),
            ],
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
                    _navigateFromNotif(Map<String, dynamic>.from(notif));
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
                            color: _notifColor(type, theme).withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _notifIcon(type),
                            color: _notifColor(type, theme),
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
      case 'new_follower':
        return Icons.person_add;
      case 'comment':
      case 'comment_reply':
        return Icons.comment;
      case 'like':
        return Icons.favorite;
      case 'reward':
        return Icons.card_giftcard;
      case 'tip_received':
      case 'episode_unlock':
        return Icons.monetization_on;
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

  Color _notifColor(String type, ThemeData theme) {
    switch (type) {
      case 'episode':
      case 'publish':
        return Colors.blue;
      case 'follower':
      case 'follow':
      case 'new_follower':
        return theme.primaryColor;
      case 'comment':
      case 'comment_reply':
        return Colors.orange;
      case 'like':
        return Colors.red;
      case 'reward':
      case 'gamification':
      case 'level_up':
      case 'achievement':
        return Colors.green;
      case 'tip_received':
      case 'episode_unlock':
        return Colors.amber;
      case 'welcome':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
