import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../shared/widgets/au_card.dart';
import '../../shared/widgets/author_tier_badge.dart';
import 'series_detail_screen.dart';
import 'theme_color_screen.dart';
import 'reader_profile_screen.dart';

class AuthorProfileScreen extends StatefulWidget {
  final int authorId;

  const AuthorProfileScreen({super.key, required this.authorId});

  @override
  State<AuthorProfileScreen> createState() => _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends State<AuthorProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _author;
  List<dynamic> _series = [];
  List<dynamic> _topSupporters = [];
  bool _isFollowing = false;
  bool _isSelf = false;
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
      final res = await ApiService.get(ApiEndpoints.authorProfile(widget.authorId));
      if (res.success && mounted) {
        final data = res.data;
        setState(() {
          _author = data['author'];
          _series = data['series'] ?? [];
          _topSupporters = data['top_supporters'] ?? [];
          _isFollowing = data['is_following'] ?? false;
          _isSelf = data['is_self'] ?? false;
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
      final res = await ApiService.post(ApiEndpoints.followToggle(widget.authorId), body: {});
      if (res.success && mounted) {
        final data = res.data;
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

  void _showTipSheet(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myCoins = authProvider.user?['coins'] ?? 0;
    final penName = _author?['pen_name'] ?? 'Author';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TipSheet(
        authorId: widget.authorId,
        penName: penName,
        myCoins: myCoins is int ? myCoins : int.tryParse('$myCoins') ?? 0,
        onSuccess: (remaining) {
          // Refresh auth profile so coin balance everywhere updates.
          authProvider.refreshProfile();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tip terkirim! Sisa koin: $remaining'),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showNotifPrefsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _NotifPrefsSheet(),
    );
  }

  String _formatCount(dynamic count) {
    final n = count is int ? count : int.tryParse(count.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }



  Color _tierColor(String? tier) {
    if (tier == 'popular' || tier == 'top') {
      return Colors.blue[500]!;
    }
    switch (tier) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
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
              ElevatedButton(onPressed: _fetchProfile, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    final penName = _author!['pen_name'] ?? 'Author';
    final bio = _author!['author_bio'] ?? '';
    final rawAvatar = _author!['author_avatar_url'];
    final avatarUrl = rawAvatar != null ? ApiService.getImageUrl(rawAvatar) : '';
    final tier = _author!['author_tier'];
    final tierCol = _tierColor(tier);

    final socialLinks = _parseSocialLinks(_author!['author_social_links']);
    final followersCount = _author!['followers_count'] ?? 0;
    final seriesCount = _author!['series_count'] ?? 0;
    final totalViews = _author!['total_views'] ?? 0;
    final isVerified = _author!['is_verified'] == true || _author!['is_verified'] == 1;
    final canTip = _author!['can_tip'] == true || _author!['can_tip'] == 1;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canEditProfile = _isSelf && authProvider.user?['role'] == 'author';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ═══════════════ HEADER ═══════════════
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.textTheme.displayLarge?.color ?? Colors.black),
            title: Text(penName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color)),
            centerTitle: true,
          ),

          // ═══════════════ PROFILE INFO ═══════════════
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Banner Background
                if (_author!['author_banner_url'] != null)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: ApiService.getImageUrl(_author!['author_banner_url']),
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.primaryColor.withValues(alpha: 0.2),
                            theme.primaryColor.withValues(alpha: 0.05),
                            theme.scaffoldBackgroundColor,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -40,
                            left: -40,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.primaryColor.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -80,
                            right: -50,
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.primaryColor.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Lighter Gradient overlay to keep image very bright but still fade into background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.0), // No darkness at top
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.2), // Very subtle fade at middle
                          theme.scaffoldBackgroundColor, // Solid background at bottom for text
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content
                Column(
                  children: [
                    const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: tierCol, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 24, offset: const Offset(0, 8)),
                      BoxShadow(color: tierCol.withAlpha(150), blurRadius: 16, spreadRadius: 4),
                      BoxShadow(color: tierCol.withAlpha(80), blurRadius: 32, spreadRadius: 8),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56, // Larger avatar
                    backgroundColor: theme.cardColor,
                    backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl, maxWidth: 300) : null,
                    child: avatarUrl.isEmpty ? Icon(Icons.person, size: 56, color: Colors.grey[400]) : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Name + Verified
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        penName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: theme.textTheme.displayLarge?.color,
                          shadows: [
                            Shadow(color: theme.scaffoldBackgroundColor, blurRadius: 8),
                            Shadow(color: theme.scaffoldBackgroundColor, blurRadius: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_document, // Mandatory Role Icon for Author
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    if (tier != null) ...[
                      const SizedBox(width: 8),
                      AuthorTierBadge(tier: tier, size: 24),
                    ] else if (isVerified) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.verified, size: 24, color: theme.primaryColor),
                    ],
                  ],
                ),

                // @username
                if ((_author!['username'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '@${_author!['username']}',
                      style: TextStyle(
                        fontSize: 15, 
                        color: theme.textTheme.bodyMedium?.color ?? Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: theme.scaffoldBackgroundColor, blurRadius: 12)],
                      ),
                    ),
                  ),

                // Author tier
                if (tier != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: tierCol.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${tier[0].toUpperCase()}${tier.substring(1)} Tier',
                      style: TextStyle(fontSize: 12, color: tierCol, fontWeight: FontWeight.w700, letterSpacing: 0.5),
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
                        fontSize: 14, 
                        color: theme.textTheme.bodyLarge?.color, 
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(color: theme.scaffoldBackgroundColor, blurRadius: 12)],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Social links
                if (socialLinks.isNotEmpty) ...[const SizedBox(height: 10), _buildSocialLinks(socialLinks, theme)],

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
                        BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat(_formatCount(seriesCount), 'Series', theme),
                        _buildStatDivider(),
                        _buildStat(_formatCount(followersCount), 'Followers', theme),
                        _buildStatDivider(),
                        _buildStat(_formatCount(totalViews), 'Views', theme),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Follow + Tip buttons (other user) OR Edit/Share (self)
                if (canEditProfile) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showEditProfileSheet(context, theme, _author),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.primaryColor,
                              side: BorderSide(color: theme.primaryColor, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final url = 'https://aureader.com/author/${widget.authorId}';
                            // ignore: deprecated_member_use
                            await Share.share(
                              'Check out my profile on AU Reader!\n$url',
                              subject: 'AU Reader Author Profile',
                            );
                          },
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textTheme.bodyLarge?.color,
                            side: BorderSide(color: Colors.grey.withAlpha(100), width: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Follow + Tip buttons (other user view)
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
                              icon: Icon(_isFollowing ? Icons.check : Icons.person_add_alt_1, size: 20),
                              label: Text(
                                _isFollowing ? 'Following' : 'Follow',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _isFollowing ? theme.cardColor : theme.primaryColor,
                                foregroundColor: _isFollowing
                                    ? theme.textTheme.bodyLarge?.color
                                    : theme.colorScheme.onPrimary,
                                side: _isFollowing ? BorderSide(color: Colors.grey.withAlpha(100), width: 2) : null,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          if (canTip) ...[
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _showTipSheet(context),
                              icon: const Icon(Icons.monetization_on_rounded, size: 18),
                              label: const Text('Tip', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                // ═══════════════════════════════════════
                // SELF-VIEW: Settings section
                // ═══════════════════════════════════════
                if (canEditProfile) ...[
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.published_with_changes_rounded,
                    iconColor: Colors.blue[600]!,
                    title: 'Switch to Reader',
                    subtitle: 'Browse series and earn XP',
                    onTap: () {
                      final authProv = Provider.of<AuthProvider>(context, listen: false);
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Switch to Reader'),
                          content: const Text('Change role to Reader? You can switch back anytime.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            FilledButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                final ok = await authProv.switchRole(role: 'reader');
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text(authProv.errorMessage ?? 'Gagal switch role')));
                                }
                              },
                              child: const Text('Switch Role'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.palette_outlined,
                    iconColor: Colors.purple[400]!,
                    title: 'Tema Warna',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeColorScreen())),
                  ),
                  _buildSettingsTile(
                    icon: Icons.notifications_outlined,
                    iconColor: Colors.blue[700]!,
                    title: 'Notifikasi',
                    subtitle: 'Kelola preferensi notifikasi',
                    onTap: () => _showNotifPrefsSheet(context),
                  ),
                  _buildSettingsTile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.red[600]!,
                    title: 'Logout',
                    onTap: () async {
                      final authProv = Provider.of<AuthProvider>(context, listen: false);
                      await authProv.logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),
              ],
            ), // Column
              ],
            ), // Stack
          ), // SliverToBoxAdapter

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
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
          children: [_buildSeriesTab(theme), _buildSupportersTab(theme), _buildAboutTab(theme)],
        ),
      ),
    );
  }

  // ─── Social Links Row ───
  Widget _buildSocialLinks(Map<String, dynamic> links, ThemeData theme) {
    String getUrl(String key) {
      final val = links[key];
      if (val is Map) {
        if (val['is_visible'] == false || val['is_visible'] == 'false') {
          return '';
        }
        return val['url']?.toString() ?? '';
      }
      if (val is String) return val;
      return '';
    }

    final socialItems = <Map<String, dynamic>>[];

    final igUrl = getUrl('instagram');
    if (igUrl.isNotEmpty) {
      socialItems.add({'icon': Icons.camera_alt_outlined, 'url': igUrl, 'label': 'IG'});
    }

    final tiktokUrl = getUrl('tiktok');
    if (tiktokUrl.isNotEmpty) {
      socialItems.add({'icon': Icons.music_note_outlined, 'url': tiktokUrl, 'label': 'TikTok'});
    }

    final wattpadUrl = getUrl('wattpad');
    if (wattpadUrl.isNotEmpty) {
      socialItems.add({'icon': Icons.auto_stories_outlined, 'url': wattpadUrl, 'label': 'Wattpad'});
    }

    final twitterUrl = getUrl('twitter');
    if (twitterUrl.isNotEmpty) {
      socialItems.add({'icon': Icons.alternate_email, 'url': twitterUrl, 'label': 'X'});
    }

    final webUrl = getUrl('website');
    if (webUrl.isNotEmpty) {
      socialItems.add({'icon': Icons.language, 'url': webUrl, 'label': 'Web'});
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
                final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
                launchUrl(uri, mode: LaunchMode.externalApplication).catchError((e) {
                  debugPrint('Gagal membuka URL: $e');
                  return false;
                });
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
                  Icon(item['icon'] as IconData, size: 14, color: theme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(fontSize: 11, color: theme.primaryColor, fontWeight: FontWeight.w500),
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
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: theme.textTheme.displayLarge?.color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500]),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_stories_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('Belum ada series', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesDetailScreen(seriesId: s['id'])));
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
            Icon(Icons.volunteer_activism_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('Belum ada supporter', style: TextStyle(color: Colors.grey[500])),
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
        final supporterId = user['id'] is int ? user['id'] as int : int.tryParse('${user['id']}');

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: supporterId == null
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReaderProfileScreen(userId: supporterId)),
                  ),
          child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: i < 3
                ? [const Color(0xFFFFF8E1), const Color(0xFFF5F5F5), const Color(0xFFFBE9E7)][i]
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: i < 3
                ? Border.all(
                    color: [const Color(0xFFFFD700), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)][i].withAlpha(80),
                  )
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  i < 3 ? medals[i] : '${i + 1}',
                  style: TextStyle(fontSize: i < 3 ? 20 : 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundImage: sAvatar.isNotEmpty ? CachedNetworkImageProvider(sAvatar, maxWidth: 150) : null,
                child: sAvatar.isEmpty ? const Icon(Icons.person, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['pen_name'] ?? user['name'] ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text('${_formatCount(total)} coins', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.monetization_on, color: Colors.amber[600], size: 20),
            ],
          ),
        ),
        );
      },
    );
  }

  // ─── About Tab ───
  Widget _buildAboutTab(ThemeData theme) {
    final bio = _author!['bio'] ?? 'No bio available.';
    final tier = _author!['author_tier'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section
          const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(bio, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6)),
          const SizedBox(height: 24),

          // Info cards
          _buildInfoCard(
            Icons.star_rounded,
            'Author Tier',
            tier != null ? '${tier[0].toUpperCase()}${tier.substring(1)}' : 'New Author',
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
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, Color color, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey.withAlpha(25), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.displayLarge?.color),
          ),
        ],
      ),
    );
  }

  // ─── Settings tile (for self-view) ───
  Widget _buildSettingsTile({
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
        decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  // ══════════════════════════════════════════════════════════
  // EDIT PROFILE BOTTOM SHEET
  // ══════════════════════════════════════════════════════════
  void _showEditProfileSheet(BuildContext ctx, ThemeData theme, Map<String, dynamic>? user) {
    final usernameCtrl = TextEditingController(text: user?['username'] ?? '');
    final penNameCtrl = TextEditingController(text: user?['pen_name'] ?? '');
    final bioCtrl = TextEditingController(text: user?['author_bio'] ?? '');

    final socialLinks = user?['author_social_links'];
    Map<String, dynamic> links = {};
    if (socialLinks != null) {
      links = socialLinks is String ? jsonDecode(socialLinks) : Map<String, dynamic>.from(socialLinks);
    }

    final igCtrl = TextEditingController(text: _extractUrl(links, 'instagram'));
    final tiktokCtrl = TextEditingController(text: _extractUrl(links, 'tiktok'));
    final wattpadCtrl = TextEditingController(text: _extractUrl(links, 'wattpad'));
    final webCtrl = TextEditingController(text: _extractUrl(links, 'website'));

    final avatarUrl = user?['author_avatar_url'] ?? '';
    final selectedAvatar = ValueNotifier<File?>(null);
    final selectedBanner = ValueNotifier<File?>(null);
    final isBannerDeleted = ValueNotifier<bool>(false);
    final isSaving = ValueNotifier<bool>(false);

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (c) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Kamera'),
                                  onTap: () => Navigator.pop(c, ImageSource.camera),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Galeri'),
                                  onTap: () => Navigator.pop(c, ImageSource.gallery),
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
                                : (avatarUrl.isNotEmpty ? NetworkImage(ApiService.getImageUrl(avatarUrl)) : null)
                                      as ImageProvider?,
                            child: file == null && avatarUrl.isEmpty
                                ? Icon(Icons.person, size: 52, color: Colors.grey[400])
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
                                border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),



              // ── Banner Upload Section ──
              const Text('Profile Banner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (user?['can_customize_banner'] == true || user?['can_customize_banner'] == 1) ...[
                ValueListenableBuilder<bool>(
                  valueListenable: isBannerDeleted,
                  builder: (context, deleted, _) {
                    return ValueListenableBuilder<File?>(
                      valueListenable: selectedBanner,
                      builder: (context, file, _) {
                        final hasExistingBanner = user?['author_banner_url'] != null && !deleted;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                              ),
                              child: file != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(file, fit: BoxFit.cover),
                                    )
                                  : hasExistingBanner
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: ApiService.getImageUrl(user!['author_banner_url']),
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
                                              const SizedBox(height: 8),
                                              Text('No banner', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                            ],
                                          ),
                                        ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picker = ImagePicker();
                                      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                                      if (pickedFile != null) {
                                        selectedBanner.value = File(pickedFile.path);
                                        isBannerDeleted.value = false;
                                      }
                                    },
                                    icon: const Icon(Icons.upload_outlined, size: 18),
                                    label: const Text('Select Banner'),
                                  ),
                                ),
                                if (file != null || hasExistingBanner) ...[
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      selectedBanner.value = null;
                                      isBannerDeleted.value = true;
                                    },
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    label: const Text('Delete'),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Recommended: 1200x400px, Max 2MB',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ] else ...[
                // Locked message for Bronze tier
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Banner Customization Locked', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'Unlock at Silver Tier (100 followers + 100 total views)',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              _editField('Username', usernameCtrl, hint: 'huruf kecil, angka, underscore'),
              _editField('Pen Name', penNameCtrl),
              _editField('Bio', bioCtrl, maxLines: 3),
              const SizedBox(height: 8),
              const Text('Social Links', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              _editField('Instagram URL', igCtrl),
              _editField('TikTok URL', tiktokCtrl),
              _editField('Wattpad URL', wattpadCtrl),
              _editField('Website URL', webCtrl),
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
                                  'username': usernameCtrl.text.trim().toLowerCase(),
                                  'pen_name': penNameCtrl.text.trim(),
                                  'author_bio': bioCtrl.text.trim(),
                                  'author_social_links': jsonEncode({
                                    'instagram': {
                                      'url': igCtrl.text.trim(),
                                      'is_visible': igCtrl.text.trim().isNotEmpty,
                                    },
                                    'tiktok': {
                                      'url': tiktokCtrl.text.trim(),
                                      'is_visible': tiktokCtrl.text.trim().isNotEmpty,
                                    },
                                    'wattpad': {
                                      'url': wattpadCtrl.text.trim(),
                                      'is_visible': wattpadCtrl.text.trim().isNotEmpty,
                                    },
                                    'website': {
                                      'url': webCtrl.text.trim(),
                                      'is_visible': webCtrl.text.trim().isNotEmpty,
                                    },
                                  }),
                                  '_method': 'PUT',
                                };

                                final files = <String, File>{};
                                if (selectedAvatar.value != null) {
                                  files['avatar'] = selectedAvatar.value!;
                                }

                                if (isBannerDeleted.value) {
                                  await ApiService.delete(ApiEndpoints.deleteBanner);
                                } else if (selectedBanner.value != null) {
                                  await ApiService.multipart(
                                    ApiEndpoints.uploadBanner,
                                    method: 'POST',
                                    files: {'banner': selectedBanner.value!},
                                  );
                                }



                                final response = await ApiService.multipart(
                                  ApiEndpoints.updateProfile,
                                  method: 'POST',
                                  fields: fields,
                                  files: files,
                                );

                                if (response.success) {
                                  // Refresh auth state so other screens show updated data
                                  if (ctx.mounted) {
                                    await Provider.of<AuthProvider>(ctx, listen: false).refreshProfile();
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }
                                  }
                                  _fetchProfile();
                                } else {
                                  debugPrint('Profile update failed: ${response.message}');
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal: ${response.message}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                debugPrint('Profile update error: $e');
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(
                                    ctx,
                                  ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                }
                              } finally {
                                isSaving.value = false;
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

  Widget _editField(String label, TextEditingController ctrl, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  String _extractUrl(Map<String, dynamic> links, String key) {
    final val = links[key];
    if (val is Map) return val['url']?.toString() ?? '';
    if (val is String) return val;
    return '';
  }

}

// ─── Notification Preferences bottom sheet ───
class _NotifPrefsSheet extends StatefulWidget {
  const _NotifPrefsSheet();

  @override
  State<_NotifPrefsSheet> createState() => _NotifPrefsSheetState();
}

class _NotifPrefsSheetState extends State<_NotifPrefsSheet> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, bool> _prefs = {};

  static const _labels = {
    'new_episode': 'Episode baru dari author yang diikuti',
    'new_follower': 'Follower baru',
    'series_like': 'Suka pada series',
    'new_comment': 'Komentar baru',
    'comment_reply': 'Balasan komentar',
    'tip_received': 'Tip diterima',
  };

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await ApiService.get(ApiEndpoints.notificationPreferences);
      if (res.success && mounted) {
        final data = res.data;
        final map = <String, bool>{};
        if (data is Map) {
          data.forEach((k, v) => map[k.toString()] = v == true);
        }
        setState(() {
          _prefs = map;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.put(ApiEndpoints.notificationPreferences, body: _prefs);
      if (mounted) Navigator.pop(context);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.notifications_outlined, color: theme.primaryColor),
              const SizedBox(width: 10),
              const Text('Preferensi Notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ..._labels.entries.map((e) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.value, style: const TextStyle(fontSize: 14)),
              value: _prefs[e.key] ?? true,
              activeThumbColor: theme.primaryColor,
              onChanged: (v) => setState(() => _prefs[e.key] = v),
            )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tip bottom sheet ───
class _TipSheet extends StatefulWidget {
  final int authorId;
  final String penName;
  final int myCoins;
  final void Function(int remaining) onSuccess;

  const _TipSheet({
    required this.authorId,
    required this.penName,
    required this.myCoins,
    required this.onSuccess,
  });

  @override
  State<_TipSheet> createState() => _TipSheetState();
}

class _TipSheetState extends State<_TipSheet> {
  static const _amounts = [10, 50, 100, 500, 1000];
  int _selected = 50;
  final _msgCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_selected > widget.myCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koin tidak cukup'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      final body = <String, dynamic>{
        'author_id': widget.authorId,
        'amount': _selected,
      };
      if (_msgCtrl.text.trim().isNotEmpty) body['message'] = _msgCtrl.text.trim();

      final res = await ApiService.post(ApiEndpoints.tip, body: body);
      if (!mounted) return;

      if (res.success) {
        final remaining = res.data?['coins_remaining'] ?? 0;
        Navigator.pop(context);
        widget.onSuccess(remaining is int ? remaining : int.tryParse('$remaining') ?? 0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAfford = _selected <= widget.myCoins;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Icon(Icons.monetization_on_rounded, color: Colors.orange[600], size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kirim Tip ke ${widget.penName}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Saldo koin kamu: ${widget.myCoins} koin',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),

          // Amount selector
          Text('Pilih jumlah koin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _amounts.map((amt) {
              final selected = _selected == amt;
              final affordable = amt <= widget.myCoins;
              return GestureDetector(
                onTap: affordable ? () => setState(() => _selected = amt) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.orange[600]
                        : affordable
                            ? theme.cardColor
                            : Colors.grey.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? Colors.orange[600]! : affordable ? Colors.grey.withAlpha(60) : Colors.transparent,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: Colors.orange.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        size: 16,
                        color: selected ? Colors.white : affordable ? Colors.orange[600] : Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$amt',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: selected ? Colors.white : affordable ? theme.textTheme.bodyLarge?.color : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Optional message
          TextField(
            controller: _msgCtrl,
            maxLines: 2,
            maxLength: 150,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Pesan (opsional)',
              hintText: 'Tulis pesan untuk ${widget.penName}...',
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              counterStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 16),

          // Send button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSending || !canAfford ? null : _send,
              icon: _isSending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isSending ? 'Mengirim...' : canAfford ? 'Kirim $_selected Koin' : 'Koin Tidak Cukup',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: canAfford ? Colors.orange[600] : Colors.grey[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || backgroundColor != oldDelegate.backgroundColor;
  }
}
