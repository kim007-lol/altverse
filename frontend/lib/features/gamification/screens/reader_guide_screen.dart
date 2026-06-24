// reader_guide_screen.dart
import 'package:flutter/material.dart';

class ReaderGuideScreen extends StatelessWidget {
  const ReaderGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Reader Guide'), backgroundColor: theme.scaffoldBackgroundColor, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Panduan Reader',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pelajari cara mendapat XP, level up, collect badges, dan compete di leaderboard!',
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Navigation
            _buildSectionTitle('Quick Navigation', Icons.explore_outlined, theme.primaryColor),
            const SizedBox(height: 12),
            _buildQuickNavCard(
              context,
              'XP & Leveling',
              'Cara mendapat XP dan naik level',
              Icons.bolt_rounded,
              Colors.orange,
              () => _scrollToSection(context, _xpSystemKey),
            ),
            _buildQuickNavCard(
              context,
              'Mission System',
              'Daily, weekly, dan lifetime missions',
              Icons.flag_outlined,
              Colors.blue,
              () => _scrollToSection(context, _missionKey),
            ),
            _buildQuickNavCard(
              context,
              'Badge Collection',
              '30+ badges untuk dikumpulkan',
              Icons.military_tech_outlined,
              Colors.purple,
              () => _scrollToSection(context, _badgeKey),
            ),
            _buildQuickNavCard(
              context,
              'Leaderboard',
              'Compete dan menangkan hadiah',
              Icons.emoji_events_outlined,
              Colors.amber,
              () => _scrollToSection(context, _leaderboardKey),
            ),
            _buildQuickNavCard(
              context,
              'Supporter Level',
              'Tier permanen berdasarkan spending',
              Icons.workspace_premium_outlined,
              Colors.purple,
              () => _scrollToSection(context, _supporterKey),
            ),
            _buildQuickNavCard(
              context,
              'Season System',
              '3 bulan kompetisi dengan rewards',
              Icons.calendar_today_outlined,
              Colors.indigo,
              () => _scrollToSection(context, _seasonKey),
            ),
            _buildQuickNavCard(
              context,
              'Coin Economy',
              'Earning, spending, dan top-up',
              Icons.monetization_on_outlined,
              Colors.green,
              () => _scrollToSection(context, _coinKey),
            ),
            const SizedBox(height: 32),

            // XP System Section
            _buildSectionTitle('XP & Leveling System', Icons.bolt_rounded, Colors.orange, key: _xpSystemKey),
            const SizedBox(height: 12),
            _buildInfoCard(
              theme,
              'Apa itu XP?',
              'XP (Experience Points) adalah poin yang kamu kumpulkan melalui berbagai aktivitas. Semakin banyak XP, semakin tinggi level kamu!',
              Icons.info_outline,
              Colors.blue,
            ),
            const SizedBox(height: 16),

            // XP Activities
            _buildXpActivityCard(theme, '💬 Comment', '5 XP', 'Max 50 XP/day (10 comments)', Colors.blue),
            _buildXpActivityCard(theme, '❤️ Like Received', '2 XP', 'Max 40 XP/day (20 likes)', Colors.pink),
            _buildXpActivityCard(theme, '🚪 Daily Login', '5 XP', 'Once per day', Colors.green),
            _buildXpActivityCard(theme, '📖 Read Episode', '3 XP', 'Max 30 XP/day (10 episodes)', Colors.purple),

            const SizedBox(height: 16),
            _buildInfoCard(
              theme,
              'Level System',
              'Level dihitung dari total XP. Level 1 = 100 XP, Level 10 = 10,000 XP, Level 100 = 1,000,000 XP. Setiap level up dapat reward!',
              Icons.trending_up,
              Colors.green,
            ),
            const SizedBox(height: 32),

            // Mission System
            _buildSectionTitle('Mission System', Icons.flag_outlined, Colors.blue, key: _missionKey),
            const SizedBox(height: 12),

            _buildMissionTypeCard(
              theme,
              '📅 Daily Missions',
              'Reset setiap hari 00:00',
              [
                '🚪 Daily Login → 10 XP',
                '📖 Read 5 episodes → 25 XP',
                '💬 Comment 3 times → 20 XP',
                '❤️ Like 5 episodes → 15 XP',
              ],
              'Total: 70 XP/day',
              Colors.blue,
            ),
            _buildMissionTypeCard(
              theme,
              '📆 Weekly Missions',
              'Reset setiap Senin 00:00',
              [
                '📚 Read 25 episodes → 150 XP',
                '💬 Comment 15 times → 100 XP',
                '👥 Follow 5 authors → 50 XP',
                '🔖 Bookmark 5 series → 50 XP',
                '🔥 Login 7 days streak → 200 XP',
              ],
              'Total: 550 XP/week',
              Colors.indigo,
            ),
            _buildMissionTypeCard(
              theme,
              '🏆 Lifetime Missions',
              'One-time achievements',
              [
                '📖 Read 100 episodes → 500 XP + 50 coins',
                '📖 Read 500 episodes → 1000 XP + 250 coins',
                '📖 Read 1000 episodes → 3000 XP + 1000 coins',
                '💬 Comment 100 times → 400 XP + 100 coins',
                '👥 Follow 50 authors → 300 XP + 100 coins',
                '🔖 Bookmark 50 series → 300 XP + 100 coins',
                '💰 Spend 500 coins → 500 XP + 200 coins',
              ],
              'Total: 6,000 XP + 1,800 coins',
              Colors.purple,
            ),
            const SizedBox(height: 32),

            // Badge System
            _buildSectionTitle('Badge Collection', Icons.military_tech_outlined, Colors.purple, key: _badgeKey),
            const SizedBox(height: 12),

            _buildBadgeCategoryCard(theme, '📖 Reader Badges', [
              '📚 Bookworm (10 chapters)',
              '📕 Avid Reader (50 chapters)',
              '📗 Scholar (100 chapters)',
              '🏆 Completionist (finish 1 AU)',
              '🏃 Marathoner (finish 10 AU)',
              '🔖 Collector (first bookmark)',
            ], Colors.blue),
            _buildBadgeCategoryCard(theme, '💬 Social Badges', [
              '💬 Vocal Reader (first comment)',
              '👫 Social Butterfly (follow 5 authors)',
              '🌐 Networker (follow 20 authors)',
              '🔥 Consistent (7 days streak)',
            ], Colors.green),
            _buildBadgeCategoryCard(theme, '💎 Supporter Badges', [
              '🥈 Perak Supporter (500 coins)',
              '🥇 Emas Supporter (1000 coins)',
              '💎 Diamond Supporter (2000 coins)',
              '💠 Platinum Supporter (5000 coins)',
              '👑 Legendary Supporter (10000 coins)',
            ], Colors.amber),
            _buildBadgeCategoryCard(theme, '⭐ Author Badges', [
              '✍️ Debut Author (first AU)',
              '⭐ Rising Star (AU 1000 views)',
              '🔥 Trending Author (AU 10K views)',
              '👥 Influencer (100 followers)',
              '📚 Storyteller (complete 1 AU)',
            ], Colors.orange),
            const SizedBox(height: 32),

            // Leaderboard
            _buildSectionTitle(
              'Leaderboard & Ranking',
              Icons.emoji_events_outlined,
              Colors.amber,
              key: _leaderboardKey,
            ),
            const SizedBox(height: 12),

            _buildLeaderboardCard(
              theme,
              '🌟 Global XP',
              'Ranking berdasarkan total XP dalam season',
              'Top 5 dapat coins: #1: 50, #2: 40, #3: 30, #4: 20, #5: 10',
              Colors.orange,
            ),
            _buildLeaderboardCard(
              theme,
              '💰 Top Supporters',
              'Ranking berdasarkan coins spent dalam season',
              'Top 3 dapat recognition badges',
              Colors.green,
            ),
            _buildLeaderboardCard(
              theme,
              '👨‍💼 Top Authors',
              'Ranking berdasarkan coins earned dalam season',
              'Top 3 dapat recognition badges',
              Colors.blue,
            ),

            const SizedBox(height: 16),
            _buildInfoCard(
              theme,
              'Season Rewards',
              'Top 5 Global XP: 🥇 50 coins, 🥈 40 coins, 🥉 30 coins, #4: 20 coins, #5: 10 coins. Top 3 Supporter & Author dapat recognition badges.',
              Icons.card_giftcard,
              Colors.amber,
            ),
            const SizedBox(height: 32),

            // Daily Reward
            _buildSectionTitle('Daily Reward System', Icons.card_giftcard_outlined, Colors.green),
            const SizedBox(height: 12),

            _buildDailyRewardCard(
              theme,
              'Streak-Based Rewards',
              [
                'Day 1: 10 XP',
                'Day 2: 20 XP',
                'Day 3: 30 XP',
                'Day 4: 40 XP',
                'Day 5: 50 XP',
                'Day 10: 100 XP',
                'Day 30: 300 XP',
              ],
              'Formula: Streak × 10 XP (unlimited growth). Maintain streak dengan login setiap hari!',
              Colors.green,
            ),
            const SizedBox(height: 32),

            // Supporter Level System
            _buildSectionTitle(
              'Supporter Level System',
              Icons.workspace_premium_outlined,
              Colors.purple,
              key: _supporterKey,
            ),
            const SizedBox(height: 12),

            _buildInfoCard(
              theme,
              'Apa itu Supporter Level?',
              'Supporter Level adalah tier permanen berdasarkan total coins yang kamu habiskan (lifetime spend). Semakin banyak support, semakin tinggi level kamu!',
              Icons.info_outline,
              Colors.purple,
            ),
            const SizedBox(height: 16),

            _buildSupporterLevelCard(theme, '🌱 Supporter', '10+ coins', 'Weight: 0', Colors.grey),
            _buildSupporterLevelCard(theme, '🥉 Bronze', '100+ coins', 'Weight: 5', Color(0xFFCD7F32)),
            _buildSupporterLevelCard(theme, '🥈 Silver', '500+ coins', 'Weight: 10', Color(0xFFC0C0C0)),
            _buildSupporterLevelCard(theme, '🥇 Gold', '2,000+ coins', 'Weight: 20', Color(0xFFFFD700)),
            _buildSupporterLevelCard(theme, '💎 Diamond', '5,000+ coins', 'Weight: 40', Color(0xFF00E5FF)),

            const SizedBox(height: 16),
            _buildInfoCard(
              theme,
              'Benefit Supporter Level',
              'Higher weight = comment priority boost! Level tinggi membuat comment kamu muncul lebih atas. Plus, badge eksklusif di profile!',
              Icons.star_outline,
              Colors.amber,
            ),
            const SizedBox(height: 32),

            // Season System
            _buildSectionTitle('Season System', Icons.calendar_today_outlined, Colors.indigo, key: _seasonKey),
            const SizedBox(height: 12),

            _buildInfoCard(
              theme,
              'Apa itu Season?',
              'Season adalah periode kompetisi 3 bulan (90 hari). Setiap season, leaderboard direset dan dimulai dari 0. Season rewards diberikan saat season berakhir.',
              Icons.info_outline,
              Colors.indigo,
            ),
            const SizedBox(height: 16),

            _buildSeasonInfoCard(
              theme,
              '📅 Duration',
              '90 days (3 months)',
              'Season otomatis rotate setelah berakhir',
              Colors.blue,
            ),
            _buildSeasonInfoCard(
              theme,
              '🏆 Rewards',
              'Top 5 XP: 10-50 coins',
              'Top 3 Supporter & Author: Recognition badges',
              Colors.green,
            ),
            _buildSeasonInfoCard(
              theme,
              '🔄 Rotation',
              'Automatic',
              'Season baru dimulai setelah season lama berakhir',
              Colors.orange,
            ),

            const SizedBox(height: 16),
            _buildInfoCard(
              theme,
              'Season Leaderboard',
              'XP, spending, dan earning dihitung per season. Ini memberikan kesempatan fair untuk semua user baru untuk compete!',
              Icons.leaderboard,
              Colors.purple,
            ),
            const SizedBox(height: 32),

            // Coin Economy
            _buildSectionTitle('Coin Economy', Icons.monetization_on_outlined, Colors.green, key: _coinKey),
            const SizedBox(height: 12),

            _buildInfoCard(
              theme,
              'Apa itu Coins?',
              'Coins adalah virtual currency untuk support author favorit kamu. Beli dengan real money, gunakan untuk unlock episode atau kirim tip!',
              Icons.info_outline,
              Colors.green,
            ),
            const SizedBox(height: 16),

            // Earning Coins
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Cara Mendapat Coins',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCoinMethodRow('💰 Top-Up', 'Beli coins dengan real money (Rp 10K - 100K)', Colors.green),
                  _buildCoinMethodRow(
                    '🎯 Complete Missions',
                    'Lifetime missions memberikan coin rewards',
                    Colors.green,
                  ),
                  _buildCoinMethodRow('🏆 Season Rewards', 'Top 5 XP dapat 10-50 coins per season', Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Spending Coins
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.remove_circle_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Cara Menggunakan Coins',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCoinMethodRow('🔓 Unlock Episodes', 'Baca premium episodes (harga varies)', Colors.orange),
                  _buildCoinMethodRow('💝 Send Tips', 'Support author favorit (min 10 coins)', Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Top-Up Packages
            _buildInfoCard(
              theme,
              'Top-Up Packages',
              '💵 Basic: Rp 10K → 100 coins\n💵 Standard: Rp 25K → 260 coins (+10 bonus)\n💵 Premium: Rp 50K → 550 coins (+50 bonus)\n💵 Whale: Rp 100K → 1,150 coins (+150 bonus)',
              Icons.shopping_cart_outlined,
              Colors.blue,
            ),
            const SizedBox(height: 32),

            // Tips Section
            _buildSectionTitle('Tips Maksimalkan XP', Icons.lightbulb_outline, Colors.amber),
            const SizedBox(height: 12),

            _buildTipsCard(theme, 'Daily Routine', [
              '✅ Login setiap hari (maintain streak untuk bonus XP)',
              '✅ Claim daily reward (streak × 10 XP)',
              '✅ Complete all daily missions (70 XP total)',
              '✅ Read 10 episodes (30 XP cap)',
              '✅ Comment 10 times (50 XP cap)',
              '✅ Engage dengan community untuk like received',
            ], Colors.teal),
            _buildTipsCard(theme, 'Weekly Goals', [
              '✅ Complete all daily missions setiap hari (70 × 7 = 490 XP)',
              '✅ Complete all weekly missions (550 XP total)',
              '✅ Maintain login streak untuk bonus XP',
              '✅ Collect new badges dari achievements',
              '✅ Aim for leaderboard top 100',
            ], Colors.indigo),
            const SizedBox(height: 32),

            // FAQ
            _buildSectionTitle('FAQ', Icons.help_outline, Colors.indigo),
            const SizedBox(height: 12),

            _buildFAQCard(
              theme,
              'Berapa maksimal XP per hari?',
              'Sekitar 225+ XP/day: 125 XP dari activities (dengan daily caps), 70 XP dari daily missions, 79 XP dari weekly missions (rata-rata), dan streak × 10 XP dari daily reward (unlimited).',
            ),
            _buildFAQCard(
              theme,
              'Bagaimana cara naik level cepat?',
              'Complete all daily missions (70 XP), maintain daily reward streak (10+ XP), read dan comment setiap hari (sampai cap 125 XP), dan complete weekly missions (550 XP total).',
            ),
            _buildFAQCard(
              theme,
              'Apakah XP bisa hilang?',
              'Tidak! XP yang sudah dikumpulkan permanent. Level juga tidak akan turun.',
            ),
            _buildFAQCard(
              theme,
              'Bagaimana cara masuk top 5 leaderboard?',
              'Maximize daily XP (225+ per day), never miss daily missions, maintain perfect streak untuk bonus XP, dan participate full season (3 bulan). Top 5 dapat 10-50 coins.',
            ),
            const SizedBox(height: 32),

            // Call to Action
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Siap Memulai?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mulai baca, complete missions, dan collect badges! Level up dan compete di leaderboard!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kembali ke Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Section keys for scrolling
  static final GlobalKey _xpSystemKey = GlobalKey();
  static final GlobalKey _missionKey = GlobalKey();
  static final GlobalKey _badgeKey = GlobalKey();
  static final GlobalKey _leaderboardKey = GlobalKey();
  static final GlobalKey _supporterKey = GlobalKey();
  static final GlobalKey _seasonKey = GlobalKey();
  static final GlobalKey _coinKey = GlobalKey();

  void _scrollToSection(BuildContext context, GlobalKey key) {
    Scrollable.ensureVisible(key.currentContext!, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color, {Key? key}) {
    return Row(
      key: key,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickNavCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                ),
                const SizedBox(height: 6),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpActivityCard(ThemeData theme, String activity, String xp, String limit, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(
              xp,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(limit, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionTypeCard(
    ThemeData theme,
    String title,
    String subtitle,
    List<String> missions,
    String total,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 12),
          ...missions.map(
            (mission) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(mission, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(
              total,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCategoryCard(ThemeData theme, String title, List<String> badges, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 10),
          ...badges.map(
            (badge) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.star, size: 14, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(badge, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(ThemeData theme, String title, String description, String reward, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(
              reward,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRewardCard(ThemeData theme, String title, List<String> rewards, String bonus, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 12),
          ...rewards.map(
            (reward) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(reward, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(bonus, style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(ThemeData theme, String title, List<String> tips, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 10),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(tip, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(ThemeData theme, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline, size: 20, color: Colors.indigo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(answer, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildSupporterLevelCard(ThemeData theme, String level, String requirement, String benefit, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(level, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requirement,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 2),
                Text(benefit, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonInfoCard(ThemeData theme, String title, String value, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.check_circle, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinMethodRow(String method, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                ),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
