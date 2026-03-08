import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../auth/screens/profile_screen.dart';
import 'my_comments_screen.dart';

class ReaderProfileScreen extends StatefulWidget {
  final int userId;
  const ReaderProfileScreen({super.key, required this.userId});

  @override
  State<ReaderProfileScreen> createState() => _ReaderProfileScreenState();
}

class _ReaderProfileScreenState extends State<ReaderProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _data;
  bool _isFollowing = false;
  bool _followLoading = false;
  bool _isSelf = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiService.get(
        ApiEndpoints.readerProfilePublic(widget.userId),
      );
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        setState(() {
          _data = body;
          _isFollowing = body['is_following'] ?? false;
          _isSelf = body['is_self'] ?? false;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);
    final was = _isFollowing;
    setState(() => _isFollowing = !was);

    try {
      final res = await ApiService.post(
        ApiEndpoints.followToggle(widget.userId),
        {},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _isFollowing = data['following'] ?? !was);
      } else {
        if (mounted) setState(() => _isFollowing = was);
      }
    } catch (_) {
      if (mounted) setState(() => _isFollowing = was);
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════
  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Color _supporterColor(String? name) {
    switch (name?.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'diamond':
        return const Color(0xFFB9F2FF);
      default:
        return Colors.grey;
    }
  }

  // ─── Social Links Helpers ───
  Map<String, dynamic> _parseSocialLinks(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  Widget _buildSocialLinks(Map<String, dynamic> links, ThemeData theme) {
    final socialItems = <Map<String, dynamic>>[];
    if (links['instagram'] != null &&
        links['instagram'].toString().isNotEmpty) {
      socialItems.add({
        'icon': Icons.camera_alt_outlined,
        'url': links['instagram'],
        'label': 'IG',
      });
    }
    if (links['tiktok'] != null && links['tiktok'].toString().isNotEmpty) {
      socialItems.add({
        'icon': Icons.music_note_outlined,
        'url': links['tiktok'],
        'label': 'TikTok',
      });
    }
    if (links['wattpad'] != null && links['wattpad'].toString().isNotEmpty) {
      socialItems.add({
        'icon': Icons.auto_stories_outlined,
        'url': links['wattpad'],
        'label': 'Wattpad',
      });
    }
    if (links['twitter'] != null && links['twitter'].toString().isNotEmpty) {
      socialItems.add({
        'icon': Icons.alternate_email,
        'url': links['twitter'],
        'label': 'X',
      });
    }
    if (links['website'] != null && links['website'].toString().isNotEmpty) {
      socialItems.add({
        'icon': Icons.language,
        'url': links['website'],
        'label': 'Web',
      });
    }

    if (socialItems.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: socialItems.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              final url = item['url'].toString();
              if (url.isNotEmpty) {
                launchUrl(
                  Uri.parse(url.startsWith('http') ? url : 'https://$url'),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 14,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasError || _data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reader Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text('Gagal memuat profil'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchProfile,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _data!['user'] as Map<String, dynamic>;
    final xp = _data!['xp'] as Map<String, dynamic>? ?? {};
    final badges = (_data!['badges'] as List?) ?? [];
    final stats = _data!['stats'] as Map<String, dynamic>? ?? {};
    final supporterLevel = user['supporter_level'] as Map<String, dynamic>?;

    final name = user['name'] ?? 'User';
    final handle = '@${user['name']?.toString().replaceAll(' ', '') ?? 'user'}';
    final bio = user['bio'] ?? '';
    final avatarUrl = ApiService.getImageUrl(user['avatar_url']);

    final level = xp['level'] ?? 0;
    final currentXp = xp['current_xp'] ?? 0;
    final nextLevelXp = xp['next_level_xp'] ?? 100;
    final xpProgress = nextLevelXp > 0
        ? (currentXp / nextLevelXp).clamp(0.0, 1.0)
        : 0.0;

    final followingCount = stats['following'] ?? 0;
    final unlockedCount = stats['unlocked'] ?? 0;

    final supporterName = supporterLevel?['name'];
    final supporterCol = _supporterColor(supporterName);

    final pinnedBadges = badges.where((b) => b['is_pinned'] == true).toList();
    final socialLinks = _parseSocialLinks(user['social_links']);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ═══════════════════════════════════════════════════
            // 1. PROFILE HEADER
            // ═══════════════════════════════════════════════════
            const SizedBox(height: 16),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: supporterName != null
                            ? supporterCol
                            : Colors.grey.shade300,
                        width: 3,
                      ),
                      boxShadow: supporterName != null
                          ? [
                              BoxShadow(
                                color: supporterCol.withAlpha(60),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 52,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                  ),
                  if (pinnedBadges.isNotEmpty)
                    Positioned(
                      bottom: -4,
                      child: Row(
                        children: pinnedBadges.take(2).map((b) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2.0,
                            ),
                            child: CachedNetworkImage(
                              imageUrl: ApiService.getImageUrl(b['icon_url']),
                              width: 28,
                              height: 28,
                              errorWidget: (context, url, error) =>
                                  const SizedBox(),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            if (handle.isNotEmpty && handle != name)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  handle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),

            // Bio
            if (bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
                child: Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Social Links
            if (socialLinks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSocialLinks(socialLinks, theme),
            ],

            const SizedBox(height: 20),

            // Edit Profile / Share / Follow
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSelf) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(role: 'reader'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = 'https://aureader.com/u/${widget.userId}';
                      // ignore: deprecated_member_use
                      await Share.share(
                        'Check out my profile on AU Reader!\n$url',
                        subject: 'AU Reader Profile',
                      );
                    },
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: _toggleFollow,
                    icon: Icon(
                      _isFollowing ? Icons.check : Icons.person_add,
                      size: 18,
                    ),
                    label: Text(_isFollowing ? 'Following' : 'Follow'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isFollowing
                          ? Colors.grey[300]
                          : theme.primaryColor,
                      foregroundColor: _isFollowing
                          ? Colors.grey[700]
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 30),

            // ═══════════════════════════════════════════════════
            // 2. READER STATS
            // ═══════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Following', _formatCount(followingCount)),
                  _buildStatDivider(),
                  _buildStatColumn(
                    'Bookmarks',
                    _formatCount(stats['bookmarks'] ?? 0),
                  ),
                  _buildStatDivider(),
                  _buildStatColumn('Unlocked', _formatCount(unlockedCount)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ═══════════════════════════════════════════════════
            // 3. XP PROGRESS & GAMIFICATION
            // ═══════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'XP Progress',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Level $level',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: theme.primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: xpProgress.toDouble(),
                        minHeight: 10,
                        backgroundColor: Colors.grey.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$currentXp / $nextLevelXp XP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════
            // 4. ACCOUNT & SETTINGS ACTIONS (ListTiles)
            // ═══════════════════════════════════════════════════
            // We only show these if the logged in user is viewing their own profile
            if (_isSelf) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'My Activity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              _buildListTile(
                icon: Icons.monetization_on_rounded,
                iconColor: Colors.amber[600]!,
                title: 'My Wallet & Coins',
                subtitle: 'Coin balance: ${user['coins'] ?? 0}',
                onTap: () {}, // Navigate to wallet
              ),
              _buildListTile(
                icon: Icons.military_tech_rounded,
                iconColor: Colors.purple[400]!,
                title: 'Badge Collection',
                subtitle: '${badges.length} badges earned',
                onTap: () {}, // Navigate to badges
              ),
              _buildListTile(
                icon: Icons.forum_rounded,
                iconColor: Colors.blue[400]!,
                title: 'My Comments',
                subtitle: 'View your comment history',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCommentsScreen()),
                  );
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              _buildListTile(
                icon: Icons.published_with_changes_rounded,
                iconColor: Colors.green[600]!,
                title: 'Switch to Author',
                subtitle: 'Manage your series and dashboard',
                onTap: () {
                  final authProv = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Switch to Author'),
                      content: const Text(
                        'Change role to Author? Game features (XP, missions, etc) will be deactivated for author profile.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await authProv.switchRole(role: 'author');
                          },
                          child: const Text('Switch Role'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.settings_rounded,
                iconColor: Colors.grey[700]!,
                title: 'Settings',
                onTap: () {}, // Navigate to settings
              ),
              _buildListTile(
                icon: Icons.help_rounded,
                iconColor: Colors.grey[700]!,
                title: 'Help Center',
                onTap: () {},
              ),
              _buildListTile(
                icon: Icons.logout_rounded,
                iconColor: Colors.red[600]!,
                title: 'Logout',
                onTap: () async {
                  final authProv = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await authProv.logout();
                },
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 40, color: Colors.grey.withAlpha(50));
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}
