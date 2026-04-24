import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'activity_screen.dart';
import 'series_detail_screen.dart';
import 'missions_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchHome();
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
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _data = jsonDecode(res.body);
            _isLoading = false;
          });
          _startCarouselTimer();
        }
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
      _carouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
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
                      // ─── Header: Greeting + Notification Bell ───
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, Reader',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[900],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Find your next favorite story.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const MissionsScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.workspace_premium,
                                    color: Colors.amber,
                                  ),
                                  tooltip: 'Misi Harian & XP',
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ActivityScreen(),
                                      ),
                                    );
                                  },
                                  icon: Badge(
                                    smallSize: 8,
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.grey[700],
                                    ),
                                  ),
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
                      _buildSection(
                        'Trending Now',
                        Icons.local_fire_department,
                        _data['trending'] ?? [],
                        theme,
                      ),
                      // ─── For You ───
                      _buildSection(
                        'For You',
                        Icons.rocket_launch,
                        _data['recommended'] ?? [],
                        theme,
                      ),
                      // ─── New Releases ───
                      _buildSection(
                        'New Releases',
                        Icons.auto_awesome,
                        _data['new_releases'] ?? [],
                        theme,
                      ),
                      // ─── Latest ───
                      _buildSection(
                        'Latest Updates',
                        Icons.new_releases,
                        _data['latest'] ?? [],
                        theme,
                      ),
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
          // Navigate to Discover tab (index 1) via parent
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[400], size: 20),
              const SizedBox(width: 10),
              Text(
                'Search series, authors...',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
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
          height: 200,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: featured.length,
            onPageChanged: (i) {
              setState(() => _currentCarousel = i);
              // Reset timer on manual swipe
              _startCarouselTimer();
            },
            itemBuilder: (_, i) {
              final s = featured[i];
              final coverUrl = s['cover_url'] != null
                  ? ApiService.getImageUrl(s['cover_url'])
                  : null;

              return GestureDetector(
                onTap: () {
                  if (s['id'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SeriesDetailScreen(seriesId: s['id']),
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[200],
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
                            color: theme.primaryColor.withAlpha(30),
                            child: const Icon(
                              Icons.auto_stories,
                              size: 48,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      else
                        Container(
                          color: theme.primaryColor.withAlpha(30),
                          child: const Icon(
                            Icons.auto_stories,
                            size: 48,
                            color: Colors.white54,
                          ),
                        ),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(180),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Text overlay
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['title'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.visibility,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatCount(s['total_views'] ?? 0),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                if (s['author'] != null) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'by ${s['author']['pen_name'] ?? 'Unknown'}',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
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
        const SizedBox(height: 10),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            featured.length,
            (i) => Container(
              width: i == _currentCarousel ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _currentCarousel
                    ? theme.primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Horizontal Section ───
  Widget _buildSection(
    String title,
    IconData icon,
    List<dynamic> items,
    ThemeData theme, {
    bool isContinue = false,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: isContinue ? 100 : 180,
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

  // ─── Series Card (vertical cover) ───
  Widget _buildSeriesCard(dynamic series, ThemeData theme) {
    final coverUrl = series['cover_url'] != null
        ? ApiService.getImageUrl(series['cover_url'])
        : null;
    final title = series['title'] ?? '';
    final author = series['author'];
    final authorName = author?['pen_name'] ?? 'Unknown';

    return GestureDetector(
      onTap: () {
        if (series['id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SeriesDetailScreen(seriesId: series['id']),
            ),
          );
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 130,
                width: 120,
                child: coverUrl != null
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.auto_stories,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.auto_stories,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            Text(
              authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Continue Reading Card (horizontal) ───
  Widget _buildContinueCard(dynamic item, ThemeData theme) {
    final coverUrl = item['cover_url'] != null
        ? ApiService.getImageUrl(item['cover_url'])
        : null;
    final title = item['title'] ?? '';
    final lastEp = item['last_episode'] ?? '';
    final epNum = item['episode_number'];

    return GestureDetector(
      onTap: () {
        final sid = item['series_id'] ?? item['id'];
        if (sid != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SeriesDetailScreen(seriesId: sid),
            ),
          );
        }
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withAlpha(25)),
        ),
        child: Row(
          children: [
            // Small cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 76,
                child: coverUrl != null
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.auto_stories,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.auto_stories,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    epNum != null ? 'Ep. $epNum — $lastEp' : lastEp,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───
  String _formatCount(dynamic n) {
    final num val = n is num ? n : 0;
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M views';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K views';
    return '${val.toInt()} views';
  }
}
