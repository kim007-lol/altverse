import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'ranking_info_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data
  Map<String, dynamic> _overview = {};
  List<dynamic> _topXp = [];
  List<dynamic> _topSupporters = [];
  List<dynamic> _topAuthors = [];
  Map<String, dynamic>? _season;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.get(ApiEndpoints.leaderboardOverview),
        ApiService.get(ApiEndpoints.leaderboardTopXp),
        ApiService.get(ApiEndpoints.leaderboardTopSupporters),
        ApiService.get(ApiEndpoints.leaderboardTopAuthors),
      ]);

      if (mounted) {
        setState(() {
          _overview = jsonDecode(results[0].body);
          final xpBody = jsonDecode(results[1].body);
          _topXp = xpBody['data'] ?? [];
          _season = xpBody['season'];

          final supporterBody = jsonDecode(results[2].body);
          _topSupporters = supporterBody['data'] ?? [];
          // Use season from supporter if xp didn't have one
          _season ??= supporterBody['season'];

          final authorBody = jsonDecode(results[3].body);
          _topAuthors = authorBody['data'] ?? [];
          _season ??= authorBody['season'];

          _isLoading = false;
        });
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
          children: [
            // ─── Header ───
            _buildHeader(theme),
            // ─── My Rank Card ───
            if (!_isLoading) _buildMyRankCard(theme),
            // ─── Tabs ───
            TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: theme.primaryColor,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Top XP'),
                Tab(text: 'Top Supporter'),
                Tab(text: 'Top Author'),
              ],
            ),
            // ─── Tab Views ───
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRankList(_topXp, 'xp'),
                        _buildRankList(_topSupporters, 'supporter'),
                        _buildRankList(_topAuthors, 'author'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final daysLeft = _season != null
        ? DateTime.parse(_season!['end_date']).difference(DateTime.now()).inDays
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: Colors.amber[700], size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                if (_season != null)
                  Text(
                    '${_season!['name']} · $daysLeft hari lagi',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RankingInfoScreen()),
            ),
            icon: Icon(Icons.info_outline, color: Colors.grey[500], size: 22),
            tooltip: 'How Ranking Works',
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankCard(ThemeData theme) {
    final mySeasonXp = _overview['my_season_xp'];
    final mySeasonSpending = _overview['my_season_spending'];
    final mySeasonEarning = _overview['my_season_earning'];
    final myXp = _overview['my_xp'];
    final myLevel = _overview['my_level'] ?? 0;
    final nextLevelXp = _overview['next_level_xp'] ?? 100;
    final totalXp = myXp?['total_xp'] ?? 0;
    final seasonXp = mySeasonXp?['xp'] ?? 0;
    final seasonSpent = mySeasonSpending?['total_spent'] ?? 0;
    final seasonEarned = mySeasonEarning?['total_earned'] ?? 0;

    final supporterLevel = _overview['my_supporter_level'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withAlpha(15),
            theme.primaryColor.withAlpha(40),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primaryColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Supporter Badge
              if (supporterLevel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _parseColor(supporterLevel['color']).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    supporterLevel['name'] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _parseColor(supporterLevel['color']),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                'Lv.$myLevel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          // XP Progress Bar
          Row(
            children: [
              Text(
                'XP $totalXp / $nextLevelXp',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: nextLevelXp > 0
                        ? (totalXp / nextLevelXp).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Season Stats Row
          Row(
            children: [
              _buildStatChip(
                icon: Icons.bolt_rounded,
                label: '$seasonXp XP',
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: Icons.monetization_on_outlined,
                label: '$seasonSpent spent',
                color: Colors.green,
              ),
              if (seasonEarned > 0) ...[
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.savings_outlined,
                  label: '$seasonEarned earned',
                  color: Colors.blue,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankList(List<dynamic> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'Belum ada data',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildRankTile(item, index + 1, type);
        },
      ),
    );
  }

  Widget _buildRankTile(Map<String, dynamic> item, int rank, String type) {
    // Extract user data (shape differs between endpoints)
    final userData = item['user'] ?? item['author'] ?? item;
    final name = userData['pen_name'] ?? userData['name'] ?? 'User';
    final avatar = userData['avatar_url'];

    // Stat value — updated for new season-based leaderboards
    String statValue;
    IconData statIcon;
    Color statColor;

    if (type == 'xp') {
      statValue = '${_formatNumber(item['xp'] ?? 0)} XP';
      statIcon = Icons.bolt_rounded;
      statColor = Colors.orange[700]!;
    } else if (type == 'supporter') {
      statValue = '${_formatNumber(item['total_spent'] ?? 0)} Coins';
      statIcon = Icons.monetization_on_outlined;
      statColor = Colors.green[700]!;
    } else {
      statValue = '${_formatNumber(item['total_earned'] ?? 0)} Coins';
      statIcon = Icons.savings_outlined;
      statColor = Colors.blue[700]!;
    }

    // Rank medal
    Widget rankWidget;
    if (rank <= 3) {
      final colors = [
        Colors.amber[700]!,
        Colors.grey[400]!,
        Colors.brown[400]!,
      ];
      final icons = [
        Icons.looks_one_rounded,
        Icons.looks_two_rounded,
        Icons.looks_3_rounded,
      ];
      rankWidget = Icon(icons[rank - 1], color: colors[rank - 1], size: 28);
    } else {
      rankWidget = SizedBox(
        width: 28,
        child: Text(
          '#$rank',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
          ),
        ),
      );
    }

    // Supporter badge (for Top XP and Top Supporter tabs)
    final supporterLevel =
        userData['supporter_level'] ?? item['supporter_level'];
    String? badgeName;
    Color? badgeColor;
    if (supporterLevel != null) {
      badgeName = supporterLevel['name'];
      badgeColor = _parseColor(supporterLevel['color']);
    }

    // Author tier (for Top Author tab)
    final authorTier = userData['author_tier'] ?? item['author_tier'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rank <= 3 ? Colors.amber.withAlpha(10) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank <= 3
              ? Colors.amber.withAlpha(40)
              : Colors.grey.withAlpha(30),
        ),
      ),
      child: Row(
        children: [
          rankWidget,
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            backgroundImage: avatar != null
                ? NetworkImage(ApiService.getImageUrl(avatar))
                : null,
            child: avatar == null
                ? Icon(Icons.person, color: Colors.grey[400], size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          // Name + Badge/Tier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (type == 'author' && authorTier != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    authorTier.toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple[400],
                    ),
                  ),
                ] else if (badgeName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    badgeName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: badgeColor ?? Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Stat
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statIcon, size: 16, color: statColor),
              const SizedBox(width: 4),
              Text(
                statValue,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic value) {
    final num = int.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
