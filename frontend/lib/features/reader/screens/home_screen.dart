import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'activity_screen.dart';
import 'series_detail_screen.dart';
import 'author_profile_screen.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/notification_provider.dart';
import '../../shared/widgets/author_tier_badge.dart';
import 'missions_screen.dart';
import 'search_screen.dart';

class ReaderHomeScreen extends StatefulWidget {
  const ReaderHomeScreen({super.key});

  @override
  State<ReaderHomeScreen> createState() => _ReaderHomeScreenState();
}

class _ReaderHomeScreenState extends State<ReaderHomeScreen> {
  Map<String, dynamic> _data = {};
  bool _isLoading = true;

  // Carousel
  final PageController _carouselController = PageController();
  Timer? _carouselTimer;
  int _currentCarousel = 0;

  // Popular Authors follow state. The FYP payload doesn't carry per-viewer
  // follow status, so cards start as "Follow" and reconcile with the server
  // response after the first tap.
  final Set<int> _followingAuthors = {};
  final Set<int> _togglingAuthors = {};

  @override
  void initState() {
    super.initState();
    _fetchHome();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>().fetchUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _fetchHome() async {
    try {
      final res = await ApiService.get(ApiEndpoints.fyp);
      if (!mounted) return;
      if (res.success) {
        setState(() {
          _data = res.data is Map<String, dynamic> ? res.data : {};
          _isLoading = false;
        });
        _startCarouselTimer();
      } else {
        // Clear the spinner even when the request fails, so the screen can
        // render its empty/error state instead of spinning forever.
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCarouselTimer() {
    final featured = (_data['featured'] ?? []) as List;
    if (featured.length <= 1) return;
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentCarousel + 1) % featured.length;
      _carouselController.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchHome,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // ─── Header: Greeting + Actions ───
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Discover', style: theme.textTheme.displaySmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Find your next favorite story',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionsScreen()));
                                  },
                                  icon: Icon(Icons.star_outline, color: theme.primaryColor),
                                  tooltip: 'Missions',
                                ),
                                IconButton(
                                  onPressed: () {
                                    final notifProvider = context.read<NotificationProvider>();
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen())).then((_) {
                                      if (mounted) {
                                        notifProvider.fetchUnreadCount();
                                      }
                                    });
                                  },
                                  icon: Consumer<NotificationProvider>(
                                    builder: (context, notifProvider, child) {
                                      if (notifProvider.unreadCount > 0) {
                                        return Badge(
                                          label: Text(notifProvider.unreadCount > 99 ? '99+' : notifProvider.unreadCount.toString()),
                                          child: Icon(Icons.notifications_none, color: theme.primaryColor),
                                        );
                                      }
                                      return Icon(Icons.notifications_none, color: theme.primaryColor);
                                    },
                                  ),
                                  tooltip: 'Notifications',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ─── Search Bar (tap to navigate) ───
                      _buildSearchBar(theme),
                      const SizedBox(height: 16),
                      // ─── Featured Carousel ───
                      _buildFeaturedCarousel(theme),
                      const SizedBox(height: 20),
                      // ─── Continue Reading ───
                      _buildSection(
                        'Continue Reading',
                        Icons.menu_book,
                        _data['continue_reading'] ?? [],
                        theme,
                        isContinue: true,
                      ),
                      // ─── Trending ───
                      _buildSection('Trending Now', Icons.local_fire_department, _data['trending'] ?? [], theme),
                      // ─── Popular Authors ───
                      _buildPopularAuthors(theme),
                      // ─── For You ───
                      _buildSection('For You', Icons.rocket_launch, _data['recommended'] ?? [], theme),
                      // ─── New Releases ───
                      _buildSection('New Releases', Icons.auto_awesome, _data['new_releases'] ?? [], theme),
                      // ─── Latest ───
                      _buildSection('Latest Updates', Icons.new_releases, _data['latest'] ?? [], theme),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ─── Search Bar ───
  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          // Navigate to search screen
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withAlpha(50), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: theme.textTheme.bodySmall?.color, size: 20),
              const SizedBox(width: 12),
              Text(
                'Search series, authors...',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Featured Carousel ───
  Widget _buildFeaturedCarousel(ThemeData theme) {
    final featured = (_data['featured'] ?? []) as List;
    if (featured.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: featured.length,
            onPageChanged: (i) {
              setState(() => _currentCarousel = i);
              _startCarouselTimer();
            },
            itemBuilder: (_, i) {
              final s = featured[i];
              final coverUrl = s['cover_url'] != null ? ApiService.getImageUrl(s['cover_url']) : null;

              return GestureDetector(
                onTap: () {
                  if (s['id'] != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesDetailScreen(seriesId: s['id'])));
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.withAlpha(25),
                    border: Border.all(color: Colors.grey.withAlpha(50), width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover image
                      if (coverUrl != null)
                        Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: theme.cardColor,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: theme.cardColor,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                            ),
                          ),
                        ),
                      ),
                      // Text overlay
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['title'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (s['author'] != null)
                              Text(
                                'by ${s['author']['pen_name'] ?? 'Unknown'}',
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            featured.length,
            (i) => Container(
              width: i == _currentCarousel ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: i == _currentCarousel ? theme.primaryColor : theme.dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Horizontal Section ───
  Widget _buildSection(String title, IconData icon, List<dynamic> items, ThemeData theme, {bool isContinue = false}) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Text(title, style: theme.textTheme.titleLarge),
        ),
        SizedBox(
          height: isContinue ? 100 : 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              if (isContinue) {
                return _buildContinueCard(item, theme);
              }
              return _buildSeriesCard(item, theme);
            },
          ),
        ),
      ],
    );
  }

  // ─── Popular Authors Section ───
  Widget _buildPopularAuthors(ThemeData theme) {
    final authors = (_data['popular_authors'] ?? []) as List;
    if (authors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Text('Popular Authors', style: theme.textTheme.titleLarge),
        ),
        SizedBox(
          height: 196,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: authors.length,
            itemBuilder: (_, i) => _buildAuthorCard(authors[i], theme),
          ),
        ),
      ],
    );
  }

  // ─── Author Card (avatar + pen name + tier + follow) ───
  Widget _buildAuthorCard(dynamic author, ThemeData theme) {
    final id = author['id'];
    final penName = (author['pen_name'] as String?)?.trim();
    final displayName = (penName != null && penName.isNotEmpty) ? penName : 'Unknown';
    final tier = author['author_tier'] as String?;
    final avatarUrl = author['avatar_url'] != null ? ApiService.getImageUrl(author['avatar_url']) : null;
    final isFollowing = id is int && _followingAuthors.contains(id);
    final isBusy = id is int && _togglingAuthors.contains(id);

    return GestureDetector(
      onTap: () {
        if (id is int) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AuthorProfileScreen(authorId: id)));
        }
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withAlpha(50), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.cardColor,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      displayName[0].toUpperCase(),
                      style: theme.textTheme.titleLarge,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (tier != null) ...[
                  const SizedBox(width: 4),
                  AuthorTierBadge(tier: tier, size: 16),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 30,
              child: OutlinedButton(
                onPressed: (id is int && !isBusy) ? () => _toggleAuthorFollow(id) : null,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: isFollowing ? theme.cardColor : theme.primaryColor,
                  foregroundColor: isFollowing ? theme.textTheme.bodyMedium?.color : Colors.white,
                  side: BorderSide(color: isFollowing ? Colors.grey.withAlpha(100) : theme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isBusy
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle follow for a popular-author card, reconciling with the server's
  // returned state so the label is correct even on the first tap.
  Future<void> _toggleAuthorFollow(int authorId) async {
    if (_togglingAuthors.contains(authorId)) return;
    final wasFollowing = _followingAuthors.contains(authorId);

    setState(() {
      _togglingAuthors.add(authorId);
      wasFollowing ? _followingAuthors.remove(authorId) : _followingAuthors.add(authorId);
    });

    try {
      final res = await ApiService.post(ApiEndpoints.followToggle(authorId), body: {});
      if (!mounted) return;
      final following = (res.success && res.data is Map) ? (res.data['following'] ?? !wasFollowing) : wasFollowing;
      setState(() => following == true ? _followingAuthors.add(authorId) : _followingAuthors.remove(authorId));
    } catch (_) {
      // Revert optimistic change on failure.
      if (mounted) {
        setState(() => wasFollowing ? _followingAuthors.add(authorId) : _followingAuthors.remove(authorId));
      }
    } finally {
      if (mounted) setState(() => _togglingAuthors.remove(authorId));
    }
  }

  // ─── Series Card (vertical cover) ───
  Widget _buildSeriesCard(dynamic series, ThemeData theme) {
    final coverUrl = series['cover_url'] != null ? ApiService.getImageUrl(series['cover_url']) : null;
    final title = series['title'] ?? '';
    final author = series['author'];
    final authorName = author?['pen_name'] ?? 'Unknown';

    return GestureDetector(
      onTap: () {
        if (series['id'] != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesDetailScreen(seriesId: series['id'])));
        }
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Container(
              height: 150,
              width: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.withAlpha(25),
                border: Border.all(color: Colors.grey.withAlpha(50), width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: coverUrl != null
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: theme.textTheme.bodySmall?.color,
                          size: 32,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: theme.textTheme.bodySmall?.color,
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(authorName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  // ─── Continue Reading Card (horizontal) ───
  Widget _buildContinueCard(dynamic item, ThemeData theme) {
    final coverUrl = item['cover_url'] != null ? ApiService.getImageUrl(item['cover_url']) : null;
    final title = item['title'] ?? '';
    final lastEp = item['last_episode'] ?? '';
    final epNum = item['episode_number'];

    return GestureDetector(
      onTap: () {
        final sid = item['series_id'] ?? item['id'];
        if (sid != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesDetailScreen(seriesId: sid)));
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withAlpha(50), width: 1),
        ),
        child: Row(
          children: [
            // Small cover
            Container(
              width: 56,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.withAlpha(25),
                border: Border.all(color: Colors.grey.withAlpha(50), width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: coverUrl != null
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 20,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 20,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    epNum != null ? 'Episode $epNum' : lastEp,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Continue Reading',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
