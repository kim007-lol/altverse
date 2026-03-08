import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

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
            onPressed: () {},
            child: Text(
              'Mark all read',
              style: TextStyle(color: theme.primaryColor, fontSize: 12),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _notifications.length,
        itemBuilder: (context, i) {
          final notif = _notifications[i];
          final isUnread = notif['read'] == 'false';
          return Container(
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
                    color: _notifColor(notif['type']!).withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _notifIcon(notif['type']!),
                    color: _notifColor(notif['type']!),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif['title']!,
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif['body']!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif['time']!,
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
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
          );
        },
      ),
    );
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'episode':
        return Icons.auto_stories;
      case 'follower':
        return Icons.person_add;
      case 'comment':
        return Icons.comment;
      case 'reward':
        return Icons.card_giftcard;
      default:
        return Icons.notifications;
    }
  }

  Color _notifColor(String type) {
    switch (type) {
      case 'episode':
        return Colors.blue;
      case 'follower':
        return Colors.purple;
      case 'comment':
        return Colors.orange;
      case 'reward':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

const _notifications = [
  {
    'type': 'episode',
    'title': 'New Episode Available!',
    'body': 'LunaWrites uploaded Episode 25 of "Moonlight Sonata"',
    'time': '2 min ago',
    'read': 'false',
  },
  {
    'type': 'follower',
    'title': 'New Follower',
    'body': 'StarGazer started following you',
    'time': '1 hour ago',
    'read': 'false',
  },
  {
    'type': 'reward',
    'title': 'Daily Reward Claimed',
    'body': 'You earned 15 coins from daily check-in',
    'time': '3 hours ago',
    'read': 'true',
  },
  {
    'type': 'comment',
    'title': 'New Comment',
    'body': 'DualSoul commented on your Series "Crimson Academy"',
    'time': '5 hours ago',
    'read': 'true',
  },
  {
    'type': 'episode',
    'title': 'New Episode Available!',
    'body': 'NightOwl uploaded Episode 16 of "Shadow Protocol"',
    'time': '1 day ago',
    'read': 'true',
  },
  {
    'type': 'follower',
    'title': 'New Follower',
    'body': 'MythMaker started following you',
    'time': '2 days ago',
    'read': 'true',
  },
];
