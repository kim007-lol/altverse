import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../shared/widgets/au_card.dart';
import 'series_detail_screen.dart';

class AuthorProfileScreen extends StatefulWidget {
  final int authorId;

  const AuthorProfileScreen({super.key, required this.authorId});

  @override
  State<AuthorProfileScreen> createState() => _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends State<AuthorProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _author;
  List<dynamic> _badges = [];
  List<dynamic> _series = [];
  List<dynamic> _topSupporters = [];
  bool _isFollowing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final res = await ApiService.get(
        ApiEndpoints.authorProfile(widget.authorId),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _author = data['author'];
          _badges = data['badges'] ?? [];
          _series = data['series'] ?? [];
          _topSupporters = data['top_supporters'] ?? [];
          _isFollowing = data['is_following'] ?? false;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_author == null) return;
    final was = _isFollowing;
    setState(() => _isFollowing = !was);
    try {
      final res = await ApiService.post(
        ApiEndpoints.followToggle(widget.authorId),
        {},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() => _isFollowing = data['following'] ?? !was);
        // Refresh profile to get updated counts/badges
        _fetchProfile();
      } else if (mounted) {
        setState(() => _isFollowing = was);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isFollowing = was);
      }
    }
  }

  String _formatCount(dynamic count) {
    final n = count is int ? count : int.tryParse(count.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Color _tierColor(String? tier) {
    switch (tier) {
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
        return Colors.grey[400]!;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasError || _author == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Author Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text('Gagal memuat profil author'),
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

    final penName = _author!['pen_name'] ?? 'Author';
    final bio = _author!['author_bio'] ?? _author!['bio'] ?? '';
    final rawAvatar = _author!['author_avatar_url'] ?? _author!['avatar_url'];
    final avatarUrl = rawAvatar != null
        ? ApiService.getImageUrl(rawAvatar)
        : '';
    final tier = _author!['author_tier'];
    final tierCol = _tierColor(tier);

    // Filter pinned badges from _badges.
    final badgesList = _badges;
    final pinnedBadges = badgesList
        .where((b) => b['is_pinned'] == true)
        .toList();

    final highestBadge = _author!['highest_badge'];
    final socialLinks = _parseSocialLinks(_author!['social_links']);
    final followersCount = _author!['followers_count'] ?? 0;
    final seriesCount = _author!['series_count'] ?? 0;
    final totalViews = _author!['total_views'] ?? 0;
    final isVerified =
        _author!['is_verified'] == true || _author!['is_verified'] == 1;
    final canTip = _author!['can_tip'] == true || _author!['can_tip'] == 1;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ═══════════════ HEADER ═══════════════
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(
              color: theme.textTheme.displayLarge?.color ?? Colors.black,
            ),
          ),

          // ═══════════════ PROFILE INFO ═══════════════
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Avatar (moved out of negative transform to prevent clipping)
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: tierCol, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: tierCol.withAlpha(60),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56, // Larger avatar
                    backgroundColor: Colors.white,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? Icon(Icons.person, size: 56, color: Colors.grey[400])
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Name + Verified
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      penName,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: theme.textTheme.displayLarge?.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_document, // Mandatory Role Icon for Author
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    if (pinnedBadges.isNotEmpty) const SizedBox(width: 8),
                    ...pinnedBadges.take(2).map((b) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: CachedNetworkImage(
                          imageUrl: ApiService.getImageUrl(b['icon_url']),
                          width: 24,
                          height: 24,
                          errorWidget: (context, url, error) =>
                              const SizedBox(),
                        ),
                      );
                    }),
                    if (isVerified) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.verified, size: 24, color: theme.primaryColor),
                    ],
                  ],
                ),

                // Highest badge
                if (highestBadge != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _hexToColor(highestBadge['color']).withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _hexToColor(highestBadge['color']).withAlpha(80),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '⭐ ',
                          style: TextStyle(
                            fontSize: 12,
                            color: _hexToColor(highestBadge['color']),
                          ),
                        ),
                        Text(
                          highestBadge['name'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _hexToColor(highestBadge['color']),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Author tier
                if (tier != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tierCol.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${tier[0].toUpperCase()}${tier.substring(1)} Tier',
                      style: TextStyle(
                        fontSize: 12,
                        color: tierCol,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],

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

                // Social links
                if (socialLinks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildSocialLinks(socialLinks, theme),
                ],

                const SizedBox(height: 24),

                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withAlpha(30)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat(_formatCount(seriesCount), 'Series', theme),
                        _buildStatDivider(),
                        _buildStat(
                          _formatCount(followersCount),
                          'Followers',
                          theme,
                        ),
                        _buildStatDivider(),
                        _buildStat(_formatCount(totalViews), 'Views', theme),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Follow + Tip buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _toggleFollow,
                            icon: Icon(
                              _isFollowing
                                  ? Icons.check
                                  : Icons.person_add_alt_1,
                              size: 20,
                            ),
                            label: Text(
                              _isFollowing ? 'Following' : 'Follow',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _isFollowing
                                  ? theme.cardColor
                                  : theme.primaryColor,
                              foregroundColor: _isFollowing
                                  ? theme.textTheme.bodyLarge?.color
                                  : Colors.white,
                              side: _isFollowing
                                  ? BorderSide(color: Colors.grey.withAlpha(50))
                                  : null,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (canTip) ...[
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: navigate to tip screen
                            },
                            icon: const Icon(
                              Icons.monetization_on_outlined,
                              size: 18,
                            ),
                            label: const Text('Tip'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Achievements section
                if (_badges.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.displayLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _badges.length,
                      itemBuilder: (context, i) {
                        final badge = _badges[i];
                        final bColor = _hexToColor(badge['color']);
                        return GestureDetector(
                          onTap: () => _showBadgeDetail(context, badge, theme),
                          child: Container(
                            width: 70,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: bColor.withAlpha(25),
                                    border: Border.all(
                                      color: bColor.withAlpha(120),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '⭐',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: bColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  badge['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: bColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),

          // ═══════════════ TAB BAR ═══════════════
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: theme.primaryColor,
                unselectedLabelColor: Colors.grey[500],
                indicatorColor: theme.primaryColor,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Series'),
                  Tab(text: 'Top Supporters'),
                  Tab(text: 'About'),
                ],
              ),
              theme.scaffoldBackgroundColor,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSeriesTab(theme),
            _buildSupportersTab(theme),
            _buildAboutTab(theme),
          ],
        ),
      ),
    );
  }

  // ─── Social Links Row ───
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
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
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

  // ─── Stat widget ───
  Widget _buildStat(String value, String label, ThemeData theme) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.displayLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 40, color: Colors.grey.withAlpha(40));
  }

  // ─── Series Tab ───
  Widget _buildSeriesTab(ThemeData theme) {
    if (_series.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text('Belum ada series', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _series.length,
      itemBuilder: (context, i) {
        final s = _series[i];
        final coverUrl = ApiService.getImageUrl(s['cover_url']);
        final rawGenre = s['genre'];
        final List<String> genres;
        if (rawGenre is List) {
          genres = rawGenre.map((g) => g.toString()).toList();
        } else if (rawGenre is String && rawGenre.isNotEmpty) {
          genres = rawGenre.split(',').map((g) => g.trim()).toList();
        } else {
          genres = <String>[];
        }
        final epCount = s['episodes_count'] ?? 0;

        return SeriesListCard(
          title: s['title'] ?? 'Untitled',
          author: _author!['pen_name'] ?? '',
          coverUrl: coverUrl,
          genres: genres,
          subtitle: '$epCount episodes',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SeriesDetailScreen(seriesId: s['id']),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Top Supporters Tab ───
  Widget _buildSupportersTab(ThemeData theme) {
    if (_topSupporters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada supporter',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final medals = ['🥇', '🥈', '🥉', '4', '5'];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _topSupporters.length,
      itemBuilder: (context, i) {
        final sup = _topSupporters[i];
        final user = sup['user'] ?? {};
        final total = sup['total_spend'] ?? 0;
        final sAvatar = ApiService.getImageUrl(user['avatar_url']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: i < 3
                ? [
                    const Color(0xFFFFF8E1),
                    const Color(0xFFF5F5F5),
                    const Color(0xFFFBE9E7),
                  ][i]
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: i < 3
                ? Border.all(
                    color: [
                      const Color(0xFFFFD700),
                      const Color(0xFFC0C0C0),
                      const Color(0xFFCD7F32),
                    ][i].withAlpha(80),
                  )
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  i < 3 ? medals[i] : '${i + 1}',
                  style: TextStyle(
                    fontSize: i < 3 ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundImage: sAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(sAvatar)
                    : null,
                child: sAvatar.isEmpty
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['pen_name'] ?? user['name'] ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_formatCount(total)} coins',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.monetization_on, color: Colors.amber[600], size: 20),
            ],
          ),
        );
      },
    );
  }

  // ─── About Tab ───
  Widget _buildAboutTab(ThemeData theme) {
    final bio = _author!['bio'] ?? 'No bio available.';
    final socialLinks = _parseSocialLinks(_author!['social_links']);
    final tier = _author!['author_tier'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Info cards
          _buildInfoCard(
            Icons.star_rounded,
            'Author Tier',
            tier != null
                ? '${tier[0].toUpperCase()}${tier.substring(1)}'
                : 'New Author',
            _tierColor(tier),
            theme,
          ),
          _buildInfoCard(
            Icons.people_alt_rounded,
            'Followers',
            _formatCount(_author!['followers_count'] ?? 0),
            theme.primaryColor,
            theme,
          ),
          _buildInfoCard(
            Icons.auto_stories_rounded,
            'Published Series',
            '${_author!['series_count'] ?? 0}',
            Colors.orange,
            theme,
          ),
          _buildInfoCard(
            Icons.remove_red_eye_rounded,
            'Total Views',
            _formatCount(_author!['total_views'] ?? 0),
            Colors.teal,
            theme,
          ),

          if (socialLinks.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Social Links',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...socialLinks.entries
                .where((e) => e.value != null && e.value.toString().isNotEmpty)
                .map(
                  (e) => ListTile(
                    leading: Icon(
                      _socialIcon(e.key),
                      color: theme.primaryColor,
                    ),
                    title: Text(
                      e.key[0].toUpperCase() + e.key.substring(1),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      e.value.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    onTap: () {
                      final url = e.value.toString();
                      launchUrl(
                        Uri.parse(
                          url.startsWith('http') ? url : 'https://$url',
                        ),
                      );
                    },
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.displayLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _socialIcon(String key) {
    switch (key.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'tiktok':
        return Icons.music_note_outlined;
      case 'twitter':
      case 'x':
        return Icons.alternate_email;
      case 'wattpad':
        return Icons.auto_stories_outlined;
      case 'website':
        return Icons.language;
      default:
        return Icons.link;
    }
  }

  void _showBadgeDetail(
    BuildContext context,
    Map<String, dynamic> badge,
    ThemeData theme,
  ) {
    final bColor = _hexToColor(badge['color']);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bColor.withAlpha(25),
                  border: Border.all(color: bColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '⭐',
                    style: TextStyle(fontSize: 28, color: bColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                badge['name'] ?? '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: bColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                badge['description'] ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              if (badge['earned_at'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Earned: ${badge['earned_at']}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab bar delegate for sticky tabs ───
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
