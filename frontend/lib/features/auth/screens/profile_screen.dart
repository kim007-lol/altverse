import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../gamification/screens/wallet_screen.dart';
import '../../gamification/screens/daily_reward_screen.dart';
import '../../gamification/screens/tier_benefit_screen.dart';
import '../../gamification/screens/ranking_info_screen.dart';
import '../../gamification/screens/badges_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String role;
  const ProfileScreen({super.key, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _gamification;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final results = await Future.wait([
        ApiService.get(ApiEndpoints.me),
        ApiService.get(ApiEndpoints.readerProfile),
      ]);

      if (mounted) {
        final authData = jsonDecode(results[0].body);
        Map<String, dynamic>? gamData;
        if (results[1].statusCode == 200) {
          gamData = jsonDecode(results[1].body);
        }
        setState(() {
          _profile = authData['user'];
          _gamification = gamData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = _profile ?? authProvider.user;
    final isAuthor = (user?['role'] ?? widget.role) == 'author';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // ═══════════════════════════════════════
                      // SECTION 1: BRANDING HEADER
                      // ═══════════════════════════════════════
                      _buildBrandingHeader(user, isAuthor, theme),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ═══════════════════════════════════
                            // SECTION 2: STATS BAR
                            // ═══════════════════════════════════
                            if (isAuthor) ...[
                              const SizedBox(height: 20),
                              _buildStatsBar(user, theme),
                            ] else ...[
                              const SizedBox(height: 20),
                              _buildReaderStats(user, theme),
                              // ═════════════════════════════════
                              // GAMIFICATION: XP Progress
                              // ═════════════════════════════════
                              const SizedBox(height: 16),
                              _buildXpProgress(theme),
                              // ═════════════════════════════════
                              // GAMIFICATION: Season Rank
                              // ═════════════════════════════════
                              const SizedBox(height: 16),
                              _buildSeasonCard(theme),
                              // ═════════════════════════════════
                              // GAMIFICATION: Activity Stats
                              // ═════════════════════════════════
                              const SizedBox(height: 16),
                              _buildActivityStats(theme),
                            ],

                            // ═══════════════════════════════════
                            // SECTION 3: SOCIAL LINKS
                            // ═══════════════════════════════════
                            if (isAuthor) ...[
                              const SizedBox(height: 24),
                              _buildSocialLinks(user, theme),
                            ],

                            // ═══════════════════════════════════
                            // SECTION 4: CREATOR SETTINGS (Owner)
                            // ═══════════════════════════════════
                            const SizedBox(height: 28),
                            _buildCreatorSettings(
                              theme,
                              isAuthor,
                              user,
                              authProvider,
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BRANDING HEADER — Cover + Avatar + Name + Tier + Bio
  // ══════════════════════════════════════════════════════════
  Widget _buildBrandingHeader(
    Map<String, dynamic>? user,
    bool isAuthor,
    ThemeData theme,
  ) {
    // Strictly separate identity based on role
    final String avatarUrl = isAuthor
        ? (user?['author_avatar_url'] ?? user?['avatar_url'] ?? '')
        : (user?['avatar_url'] ?? '');

    final String displayName = isAuthor
        ? (user?['pen_name'] ?? user?['name'] ?? 'Author')
        : (user?['name'] ?? 'Reader');

    final String bio = isAuthor
        ? (user?['author_bio'] ?? user?['bio'] ?? '')
        : (user?['bio'] ?? '');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover gradient
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor,
                theme.primaryColor.withAlpha(160),
                theme.primaryColor.withAlpha(80),
              ],
            ),
          ),
        ),

        // Content overlapping cover
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 90, 20, 0),
          child: Column(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 4,
                  ),
                ),
                child: _buildAvatar(avatarUrl, theme),
              ),
              const SizedBox(height: 12),

              // Role Icon + Name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAuthor ? Icons.edit_document : Icons.menu_book_rounded,
                    size: 18,
                    color: isAuthor ? Colors.amber[700] : theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Username (@)
              if (isAuthor && user?['name'] != null) ...[
                const SizedBox(height: 2),
                Text(
                  '@${user!['name']}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],

              // Badges Row (Max 2 Badges)
              if (user?['pinned_badges'] != null &&
                  (user!['pinned_badges'] as List).isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: (user['pinned_badges'] as List).take(2).map((b) {
                    final badge = b as Map;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Tooltip(
                        message: badge['name'] ?? '',
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.transparent,
                          backgroundImage: NetworkImage(
                            ApiService.getImageUrl(badge['icon_url']),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Bio
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Action Buttons
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionButton(
                    'Edit Profile',
                    Icons.edit_outlined,
                    theme,
                    () => _showEditProfileSheet(context, theme, user),
                  ),
                  const SizedBox(width: 10),
                  _actionButton(
                    'Share',
                    Icons.share_outlined,
                    theme,
                    () {},
                    outlined: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // STATS BAR — Series / Followers / Level
  // ══════════════════════════════════════════════════════════
  Widget _buildStatsBar(Map<String, dynamic>? user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(25)),
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Series',
            value: '${user?['series_count'] ?? 0}',
            theme: theme,
          ),
          _verticalDivider(),
          _StatItem(
            label: 'Followers',
            value: _formatCount(user?['followers_count'] ?? 0),
            theme: theme,
          ),
          _verticalDivider(),
          _StatItem(
            label: 'Views',
            value: _formatCount(user?['total_views'] ?? 0),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildReaderStats(Map<String, dynamic>? user, ThemeData theme) {
    final stats = _gamification?['stats'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(25)),
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Following',
            value: '${stats?['following'] ?? 0}',
            theme: theme,
          ),
          _verticalDivider(),
          _StatItem(
            label: 'Bookmarks',
            value: '${stats?['bookmarks'] ?? 0}',
            theme: theme,
          ),
          _verticalDivider(),
          _StatItem(
            label: 'Unlocked',
            value: '${stats?['unlocked_episodes'] ?? 0}',
            theme: theme,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // GAMIFICATION: XP Progress Bar
  // ══════════════════════════════════════════════════════════
  Widget _buildXpProgress(ThemeData theme) {
    final xp = _gamification?['xp'];
    final totalXp = xp?['total_xp'] ?? 0;
    final level = xp?['level'] ?? 0;
    final nextLevelXp = xp?['next_level_xp'] ?? 100;
    final progress = nextLevelXp > 0
        ? (totalXp / nextLevelXp).clamp(0.0, 1.0)
        : 0.0;

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
              Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'XP Progress',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Text(
                'Level $level',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$totalXp / $nextLevelXp XP',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // GAMIFICATION: Season Rank Card
  // ══════════════════════════════════════════════════════════
  Widget _buildSeasonCard(ThemeData theme) {
    final season = _gamification?['season'];
    final seasonGlobal = _gamification?['season_global'];
    final seasonAuthorRanks =
        _gamification?['season_author_ranks'] as List<dynamic>? ?? [];

    if (season == null) {
      return const SizedBox.shrink();
    }

    final daysLeft = DateTime.parse(
      season['end_date'],
    ).difference(DateTime.now()).inDays;
    final globalRank = seasonGlobal?['rank'] ?? 0;
    final globalXp = seasonGlobal?['xp'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withAlpha(10),
            Colors.deepPurple.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: Colors.amber[700],
              ),
              const SizedBox(width: 6),
              Text(
                season['name'] ?? 'Current Season',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$daysLeft days left',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _seasonStatTile(
                  'Global Rank',
                  globalRank > 0 ? '#$globalRank' : '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _seasonStatTile('Season XP', '$globalXp')),
            ],
          ),
          if (seasonAuthorRanks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Top Author Support',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            ...seasonAuthorRanks.take(3).map((r) {
              final author = r['author'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: author?['avatar_url'] != null
                          ? NetworkImage(
                              ApiService.getImageUrl(author['avatar_url']),
                            )
                          : null,
                      child: author?['avatar_url'] == null
                          ? Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        author?['pen_name'] ?? author?['name'] ?? 'Author',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${r['xp']} XP',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _seasonStatTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // GAMIFICATION: Activity Stats
  // ══════════════════════════════════════════════════════════
  Widget _buildActivityStats(ThemeData theme) {
    final user = _gamification?['user'];
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
              Icon(Icons.bar_chart_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Activity',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _activityRow('Coins', '${_profile?['coins'] ?? 0}'),
          _activityRow(
            'Lifetime Support',
            '${user?['lifetime_spend'] ?? 0} coins',
          ),
          _activityRow('Member Since', _formatDate(user?['created_at'])),
          const SizedBox(height: 8),
          // How Ranking Works link
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RankingInfoScreen()),
              ),
              icon: Icon(
                Icons.info_outline,
                size: 16,
                color: theme.primaryColor,
              ),
              label: Text(
                'How Ranking Works',
                style: TextStyle(fontSize: 12, color: theme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final d = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return '—';
    }
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 32, color: Colors.grey.withAlpha(30));
  }

  // ══════════════════════════════════════════════════════════
  // SOCIAL LINKS
  // ══════════════════════════════════════════════════════════
  Widget _buildSocialLinks(Map<String, dynamic>? user, ThemeData theme) {
    final socialLinks = user?['social_links'];
    if (socialLinks == null) return const SizedBox.shrink();

    final Map<String, dynamic> links = socialLinks is String
        ? jsonDecode(socialLinks)
        : Map<String, dynamic>.from(socialLinks);

    final visibleLinks = <MapEntry<String, dynamic>>[];
    for (final entry in links.entries) {
      if (entry.value is Map) {
        final data = entry.value as Map;
        final url = data['url']?.toString() ?? '';
        final isVisible = data['is_visible'] == true;
        if (url.isNotEmpty && isVisible) visibleLinks.add(entry);
      } else if (entry.value is String && (entry.value as String).isNotEmpty) {
        visibleLinks.add(entry);
      }
    }

    if (visibleLinks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.link, size: 16, color: theme.primaryColor),
            ),
            const SizedBox(width: 8),
            const Text(
              'Connect',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...visibleLinks.map((entry) {
          final platform = entry.key;
          String url;
          if (entry.value is Map) {
            url = (entry.value as Map)['url']?.toString() ?? '';
          } else {
            url = entry.value.toString();
          }
          return _socialLinkRow(
            _socialIcon(platform),
            _capitalize(platform),
            url,
            theme,
          );
        }),
      ],
    );
  }

  Widget _socialLinkRow(
    IconData icon,
    String platform,
    String url,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.grey[700], size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                platform,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.open_in_new, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // CREATOR SETTINGS (Private — Owner Only)
  // ══════════════════════════════════════════════════════════
  Widget _buildCreatorSettings(
    ThemeData theme,
    bool isAuthor,
    Map<String, dynamic>? user,
    AuthProvider authProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isAuthor ? 'Creator Settings' : 'Account',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Settings card
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withAlpha(25)),
          ),
          child: Column(
            children: [
              _settingsTile(
                theme,
                '🔄',
                isAuthor ? 'Switch to Reader' : 'Switch to Author',
                'Ubah role aktif Anda',
                () => _showSwitchRoleDialog(
                  context,
                  theme,
                  user,
                  authProvider,
                  !isAuthor,
                ),
              ),
              _dividerThin(),
              _settingsTile(
                theme,
                '💰',
                'My Wallet & Coins',
                '${user?['coins'] ?? 0} coins',
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
              ),
              _dividerThin(),
              _settingsTile(
                theme,
                '⭐',
                'Daily Rewards & Level',
                'Level ${user?['level'] ?? 1}',
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DailyRewardScreen()),
                ),
              ),
              _dividerThin(),
              _settingsTile(
                theme,
                '🎖️',
                'Koleksi Badges',
                'Atur pin badge',
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const BadgesScreen())),
              ),
              if (isAuthor) ...[
                _dividerThin(),
                _settingsTile(
                  theme,
                  '💎',
                  'Tiers & Benefits',
                  '${_tierEmoji(user?['author_tier'] ?? 'bronze')} ${_capitalize(user?['author_tier'] ?? 'bronze')}',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TierBenefitScreen(),
                    ),
                  ),
                ),
              ],
              _dividerThin(),
              _settingsTile(theme, '⚙️', 'Settings', null, () {}),
              _dividerThin(),
              _settingsTile(theme, '🚪', 'Log Out', null, () async {
                final router = GoRouter.of(context);
                await authProvider.logout();
                router.go('/login');
              }, isDestructive: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsTile(
    ThemeData theme,
    String emoji,
    String title,
    String? subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDestructive ? Colors.red : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDestructive ? Colors.red[300] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dividerThin() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey.withAlpha(25),
      indent: 50,
    );
  }

  // ══════════════════════════════════════════════════════════
  // EXTRAS DIALOGS (SWITCH ROLE & EDIT)
  // ══════════════════════════════════════════════════════════
  void _showSwitchRoleDialog(
    BuildContext ctx,
    ThemeData theme,
    Map<String, dynamic>? user,
    AuthProvider authProvider,
    bool targetIsAuthor,
  ) {
    final bool needsPenName =
        targetIsAuthor && (user?['pen_name'] ?? '').toString().trim().isEmpty;

    // If user needs to create Author profile for the first time,
    // redirect to the dedicated Author Onboarding screen
    if (needsPenName) {
      context.push('/author-onboarding');
      return;
    }

    showDialog(
      context: ctx,
      builder: (context) {
        bool switching = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                targetIsAuthor ? 'Switch to Author' : 'Switch to Reader',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetIsAuthor
                        ? 'Sebagai Author, Anda akan menggunakan identitas "${user?['pen_name'] ?? 'Author'}" yang terpisah dari profil Reader.'
                        : 'Sebagai Reader, Anda akan kembali menggunakan profil Pembaca "${user?['name'] ?? 'Reader'}".',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withAlpha(25)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue[400],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            targetIsAuthor
                                ? 'Fitur Gamifikasi (XP, Misi) akan dinonaktifkan di mode Author.'
                                : 'Fitur Gamifikasi (XP, Misi) akan aktif kembali di mode Reader.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: switching ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                FilledButton(
                  onPressed: switching
                      ? null
                      : () async {
                          setState(() => switching = true);
                          final success = await authProvider.switchRole(
                            role: targetIsAuthor ? 'author' : 'reader',
                          );

                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              _fetchProfile(); // refresh data
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    targetIsAuthor
                                        ? 'Switch ke Author Mode ✍️'
                                        : 'Switch ke Reader Mode 📖',
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              setState(() => switching = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    authProvider.errorMessage ??
                                        'Gagal switch role',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: switching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // EDIT PROFILE BOTTOM SHEET
  // ══════════════════════════════════════════════════════════
  void _showEditProfileSheet(
    BuildContext ctx,
    ThemeData theme,
    Map<String, dynamic>? user,
  ) {
    final nameCtrl = TextEditingController(text: user?['name'] ?? '');
    final penNameCtrl = TextEditingController(text: user?['pen_name'] ?? '');
    final bioCtrl = TextEditingController(text: user?['bio'] ?? '');

    final socialLinks = user?['social_links'];
    Map<String, dynamic> links = {};
    if (socialLinks != null) {
      links = socialLinks is String
          ? jsonDecode(socialLinks)
          : Map<String, dynamic>.from(socialLinks);
    }

    final igCtrl = TextEditingController(text: _extractUrl(links, 'instagram'));
    final tiktokCtrl = TextEditingController(
      text: _extractUrl(links, 'tiktok'),
    );
    final wattpadCtrl = TextEditingController(
      text: _extractUrl(links, 'wattpad'),
    );
    final webCtrl = TextEditingController(text: _extractUrl(links, 'website'));

    final isAuthor = (user?['role'] ?? widget.role) == 'author';
    final avatarUrl = user?['avatar_url'] ?? '';

    // Use a ValueNotifier so the StatelessBuilder in the bottom sheet can react
    final selectedAvatar = ValueNotifier<File?>(null);
    final isSaving = ValueNotifier<bool>(false);

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ── Avatar Picker ──
              Center(
                child: ValueListenableBuilder<File?>(
                  valueListenable: selectedAvatar,
                  builder: (context, file, _) {
                    return GestureDetector(
                      onTap: () async {
                        final source = await showModalBottomSheet<ImageSource>(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          builder: (c) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Kamera'),
                                  onTap: () =>
                                      Navigator.pop(c, ImageSource.camera),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Galeri'),
                                  onTap: () =>
                                      Navigator.pop(c, ImageSource.gallery),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (source != null) {
                          final picked = await ImagePicker().pickImage(
                            source: source,
                            maxWidth: 512,
                            maxHeight: 512,
                            imageQuality: 85,
                          );
                          if (picked != null) {
                            selectedAvatar.value = File(picked.path);
                          }
                        }
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: file != null
                                ? FileImage(file)
                                : (avatarUrl.isNotEmpty
                                          ? NetworkImage(
                                              ApiService.getImageUrl(avatarUrl),
                                            )
                                          : null)
                                      as ImageProvider?,
                            child: file == null && avatarUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 52,
                                    color: Colors.grey[400],
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              _editField('Nama', nameCtrl),
              if (isAuthor) _editField('Pen Name', penNameCtrl),
              _editField('Bio', bioCtrl, maxLines: 3),
              if (isAuthor) ...[
                const SizedBox(height: 8),
                const Text(
                  'Social Links',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _editField('Instagram URL', igCtrl),
                _editField('TikTok URL', tiktokCtrl),
                _editField('Wattpad URL', wattpadCtrl),
                _editField('Website URL', webCtrl),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<bool>(
                  valueListenable: isSaving,
                  builder: (context, saving, _) {
                    return FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              isSaving.value = true;
                              try {
                                final fields = <String, String>{
                                  'name': nameCtrl.text.trim(),
                                  'bio': bioCtrl.text.trim(),
                                };
                                if (isAuthor) {
                                  fields['pen_name'] = penNameCtrl.text.trim();
                                  fields['social_links'] = jsonEncode({
                                    'instagram': {
                                      'url': igCtrl.text.trim(),
                                      'is_visible': igCtrl.text
                                          .trim()
                                          .isNotEmpty,
                                    },
                                    'tiktok': {
                                      'url': tiktokCtrl.text.trim(),
                                      'is_visible': tiktokCtrl.text
                                          .trim()
                                          .isNotEmpty,
                                    },
                                    'wattpad': {
                                      'url': wattpadCtrl.text.trim(),
                                      'is_visible': wattpadCtrl.text
                                          .trim()
                                          .isNotEmpty,
                                    },
                                    'website': {
                                      'url': webCtrl.text.trim(),
                                      'is_visible': webCtrl.text
                                          .trim()
                                          .isNotEmpty,
                                    },
                                  });
                                }

                                final files = <String, File>{};
                                if (selectedAvatar.value != null) {
                                  files['avatar'] = selectedAvatar.value!;
                                }

                                final response = await ApiService.multipart(
                                  ApiEndpoints.updateProfile,
                                  method: 'PUT',
                                  fields: fields,
                                  files: files,
                                );

                                if (response.statusCode == 200) {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _fetchProfile();
                                } else {
                                  debugPrint(
                                    'Profile update failed: ${response.body}',
                                  );
                                }
                              } catch (e) {
                                debugPrint('Profile update error: $e');
                              } finally {
                                isSaving.value = false;
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════
  Widget _buildAvatar(String? avatarUrl, ThemeData theme) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      final imageUrl = ApiService.getImageUrl(avatarUrl);
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {},
      );
    }
    return CircleAvatar(
      radius: 48,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, size: 48, color: theme.primaryColor),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    ThemeData theme,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return Material(
      color: outlined ? Colors.transparent : theme.primaryColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withAlpha(60)),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: outlined ? Colors.grey[700] : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: outlined ? Colors.grey[700] : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ══════════════════════════════════════════════════════════
  String _extractUrl(Map<String, dynamic> links, String key) {
    final val = links[key];
    if (val is Map) return val['url']?.toString() ?? '';
    if (val is String) return val;
    return '';
  }

  String _tierEmoji(String tier) {
    return switch (tier) {
      'popular' => '👑',
      'gold' => '🥇',
      'silver' => '🥈',
      _ => '🥉',
    };
  }

  String _formatCount(dynamic n) {
    final num val = n is num ? n : 0;
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toInt().toString();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  IconData _socialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'tiktok':
        return Icons.music_note_outlined;
      case 'twitter':
      case 'twitter/x':
        return Icons.alternate_email;
      case 'facebook':
        return Icons.facebook_outlined;
      case 'wattpad':
        return Icons.menu_book_outlined;
      case 'website':
        return Icons.language_outlined;
      default:
        return Icons.link;
    }
  }

  Future<void> _launchUrl(String url) async {
    String fullUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      fullUrl = 'https://$url';
    }
    try {
      await launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }
}

// ══════════════════════════════════════════════════════════
// STAT ITEM WIDGET
// ══════════════════════════════════════════════════════════
class _StatItem extends StatelessWidget {
  final String label, value;
  final ThemeData theme;

  const _StatItem({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
