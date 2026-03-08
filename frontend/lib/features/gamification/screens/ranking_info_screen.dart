import 'package:flutter/material.dart';

class RankingInfoScreen extends StatelessWidget {
  const RankingInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ranking & Badge System'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Intro ───
            Text(
              'How the ranking system works',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Support your favorite authors and earn prestige. The more you interact, the higher your rank.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Section 1: XP System ───
            _buildSection(
              theme,
              icon: Icons.trending_up_rounded,
              color: Colors.blue,
              title: 'XP System',
              children: [
                _infoTile('Comment on episodes', '+2 XP'),
                _infoTile('Unlock premium episode', '+5 XP'),
                _infoTile('Send tip/gift', '+20 XP'),
                _infoTile('Daily login', '+1 XP'),
                _infoTile('Read 5 episodes', '+3 XP'),
                const SizedBox(height: 12),
                _descText(
                  'Your level is based on total lifetime XP. Higher level = comment priority boost.',
                ),
                const SizedBox(height: 8),
                _formulaBox(
                  'Level Formula',
                  'XP needed = 100 × current level\nLevel 1 → 100 XP\nLevel 5 → 500 XP\nLevel 10 → 1,000 XP',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Section 2: Supporter Tiers ───
            _buildSection(
              theme,
              icon: Icons.shield_rounded,
              color: Colors.amber[700]!,
              title: 'Supporter Tiers (Permanent)',
              children: [
                _tierRow('Supporter', '10+ coins', Colors.grey),
                _tierRow('Bronze', '100+ coins', const Color(0xFFCD7F32)),
                _tierRow('Silver', '500+ coins', const Color(0xFFC0C0C0)),
                _tierRow('Gold', '2,000+ coins', const Color(0xFFFFD700)),
                _tierRow('Diamond', '5,000+ coins', const Color(0xFF00E5FF)),
                const SizedBox(height: 12),
                _descText(
                  'Supporter badges are permanent and based on your total lifetime spending. They never reset.',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Section 3: Season System ───
            _buildSection(
              theme,
              icon: Icons.emoji_events_rounded,
              color: Colors.deepPurple,
              title: 'Season System (90 Days)',
              children: [
                _descText(
                  'Every 90 days, seasonal rankings reset and a new season begins. '
                  'Earn season XP through all activities. Only the Top 1–5 receive exclusive rewards.',
                ),
                const SizedBox(height: 12),
                _rewardRow(
                  '#1',
                  '100 coins + Exclusive Frame + 7-day Early Access',
                ),
                _rewardRow(
                  '#2',
                  '75 coins + Premium Frame + 5-day Early Access',
                ),
                _rewardRow(
                  '#3',
                  '50 coins + Premium Frame + 3-day Early Access',
                ),
                _rewardRow('#4–5', '25 coins + Season Badge'),
                const SizedBox(height: 12),
                _descText(
                  'Per-Author rankings also exist. Support a specific author to rank higher on their supporter leaderboard.',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Section 4: Comment Priority ───
            _buildSection(
              theme,
              icon: Icons.forum_rounded,
              color: Colors.teal,
              title: 'Comment Priority System',
              children: [
                _descText(
                  'Comments are sorted by a priority score so that the most engaged readers\' comments appear first.',
                ),
                const SizedBox(height: 12),
                _formulaBox(
                  'Priority Score Formula',
                  'Score = (likes × 2)\n'
                      '      + (reader level × 1.5)\n'
                      '      + (supporter weight)\n'
                      '      + (season rank bonus)',
                ),
                const SizedBox(height: 12),
                _descText(
                  'This means quality and consistency matter more than spending alone.',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Section 5: Fair Play ───
            _buildSection(
              theme,
              icon: Icons.verified_user_rounded,
              color: Colors.green,
              title: 'Fair Play',
              children: [
                _bulletItem('Anti-spam detection on comments'),
                _bulletItem('Donation fraud protection'),
                _bulletItem('No XP farming allowed'),
                _bulletItem('Season rewards only for Top 1–5'),
                const SizedBox(height: 12),
                _descText(
                  'We keep the economy healthy and competition fair. Only genuine engagement is rewarded.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Builder ───
  static Widget _buildSection(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ─── Helpers ───
  static Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tierRow(String name, String requirement, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color == Colors.grey ? Colors.grey[600] : color,
              ),
            ),
          ),
          Text(
            requirement,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  static Widget _rewardRow(String rank, String reward) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              rank,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.amber[800],
              ),
            ),
          ),
          Expanded(
            child: Text(
              reward,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _formulaBox(String title, String formula) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formula,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _descText(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
    );
  }
}
