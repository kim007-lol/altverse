import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'series_detail_screen.dart';
import 'reader_profile_screen.dart';
import 'author_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _selectedGenre = 'all';
  String _sortBy = 'trending';
  List<dynamic> _results = [];
  List<dynamic> _userResults = [];
  int _totalResults = 0;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  Timer? _debounce;

  static const _genres = [
    'All',
    'Romance',
    'Action',
    'Fantasy',
    'Comedy',
    'Horror',
    'Thriller',
    'Sci-Fi',
    'Slice of Life',
    'Drama',
    'Adventure',
    'Mystery',
    'Sports',
  ];

  static const _sortOptions = [
    {
      'key': 'trending',
      'label': 'Trending',
      'icon': Icons.local_fire_department,
    },
    {'key': 'popular', 'label': 'Most Popular', 'icon': Icons.emoji_events},
    {'key': 'new', 'label': 'Terbaru', 'icon': Icons.new_releases},
    {'key': 'liked', 'label': 'Most Liked', 'icon': Icons.favorite},
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _performSearch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ─── Infinite scroll ───
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _resetAndSearch();
    });
  }

  void _resetAndSearch() {
    setState(() {
      _results = [];
      _currentPage = 1;
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    try {
      final params = <String, String>{
        'sort': _sortBy,
        'page': _currentPage.toString(),
      };
      if (_searchCtrl.text.trim().isNotEmpty) {
        params['q'] = _searchCtrl.text.trim();
      }
      if (_selectedGenre != 'all' && _selectedGenre != 'All') {
        params['genre'] = _selectedGenre;
      }

      final qs = params.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');

      final response = await ApiService.get('${ApiEndpoints.search}?$qs');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results = data['data'] ?? [];
          _userResults = data['users'] ?? [];
          _totalResults = data['total'] ?? 0;
          _currentPage = data['current_page'] ?? 1;
          _lastPage = data['last_page'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint('Discover error: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);

    try {
      final params = <String, String>{
        'sort': _sortBy,
        'page': (_currentPage + 1).toString(),
      };
      if (_searchCtrl.text.trim().isNotEmpty) {
        params['q'] = _searchCtrl.text.trim();
      }
      if (_selectedGenre != 'all' && _selectedGenre != 'All') {
        params['genre'] = _selectedGenre;
      }

      final qs = params.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');

      final response = await ApiService.get('${ApiEndpoints.search}?$qs');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results.addAll(data['data'] ?? []);
          _currentPage = data['current_page'] ?? _currentPage;
          _lastPage = data['last_page'] ?? _lastPage;
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Discover',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (!_isLoading && _totalResults > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_totalResults series',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ─── Search Bar ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari judul series atau nama author...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _resetAndSearch();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // ─── Genre Tabs ───
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _genres.length,
                itemBuilder: (ctx, i) {
                  final genre = _genres[i];
                  final key = genre.toLowerCase();
                  final isSelected =
                      _selectedGenre == key ||
                      (i == 0 && _selectedGenre == 'all');
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedGenre = key);
                        _resetAndSearch();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primaryColor
                              : theme.primaryColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          genre,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ─── Sort Tabs ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _sortOptions.map<Widget>((opt) {
                    final isActive = _sortBy == opt['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _sortBy = opt['key'] as String);
                          _resetAndSearch();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                opt['icon'] as IconData,
                                size: 14,
                                color: isActive
                                    ? Colors.white
                                    : Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                opt['label'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ─── Results ───
            Expanded(
              child: _isLoading
                  ? _buildSkeleton()
                  : (_results.isEmpty && _userResults.isEmpty)
                  ? _buildEmpty()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      itemCount:
                          (_userResults.isNotEmpty ? 1 : 0) +
                          _results.length +
                          (_isLoadingMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        // User results section
                        if (_userResults.isNotEmpty && i == 0) {
                          return _buildUserResultsSection(theme);
                        }
                        final seriesIdx = i - (_userResults.isNotEmpty ? 1 : 0);
                        if (seriesIdx >= _results.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return _RankCard(
                          rank: seriesIdx + 1,
                          series: _results[seriesIdx],
                          theme: theme,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Skeleton ───
  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 6,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 72,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 130,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 90,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hasil ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba kata kunci atau genre lain',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ─── User Results Section ───
  Widget _buildUserResultsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.people, size: 16, color: theme.primaryColor),
              const SizedBox(width: 6),
              Text(
                'Users',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        ..._userResults.map((user) {
          final u = user as Map<String, dynamic>;
          final avatarUrl = ApiService.getImageUrl(u['avatar_url']);
          final name = u['pen_name'] ?? 'Unknown';
          final handle = u['name'] ?? '';
          final role = u['role'] ?? 'reader';
          final level = u['level'] ?? 0;
          final followersCount = u['followers_count'] ?? 0;
          final supporter = u['supporter_level'] as Map<String, dynamic>?;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withAlpha(25)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                final uid = u['id'];
                if (uid == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => role == 'author'
                        ? AuthorProfileScreen(authorId: uid)
                        : ReaderProfileScreen(userId: uid),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 24,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Name + info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (supporter != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  supporter['icon']?.toString() ?? '💎',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: role == 'author'
                                      ? Colors.purple.withAlpha(20)
                                      : theme.primaryColor.withAlpha(15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  role == 'author'
                                      ? 'Author'
                                      : 'Lv.$level Reader',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: role == 'author'
                                        ? Colors.purple
                                        : theme.primaryColor,
                                  ),
                                ),
                              ),
                              if (handle.isNotEmpty && handle != name) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '@$handle',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Followers
                    Column(
                      children: [
                        Text(
                          _formatFollowers(followersCount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'followers',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.auto_stories, size: 16, color: theme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  'Series',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatFollowers(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ═══════════════════════════════════════════════════════
// Rank Card — List item with rank badge
// ═══════════════════════════════════════════════════════
class _RankCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> series;
  final ThemeData theme;

  const _RankCard({
    required this.rank,
    required this.series,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final title = series['title'] ?? 'No Title';
    final authorData = series['author'];
    final authorName = authorData != null
        ? (authorData['pen_name'] ?? 'Unknown')
        : 'Unknown';
    final genre = series['genre'] ?? '';
    final episodesCount = series['episodes_count'] ?? 0;
    final totalViews = series['total_views'] ?? 0;
    final totalLikes = series['total_likes'] ?? 0;
    final coverUrl = series['cover_url'];
    final imageUrl = coverUrl != null ? ApiService.getImageUrl(coverUrl) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3
            ? Border.all(color: _rankColor(rank).withAlpha(40), width: 1.5)
            : Border.all(color: Colors.grey.withAlpha(20)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final seriesId = series['id'];
          if (seriesId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SeriesDetailScreen(seriesId: seriesId),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ─── Rank Badge ───
              _RankBadge(rank: rank),
              const SizedBox(width: 10),

              // ─── Cover ───
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 100,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (c, e, s) => _coverPlaceholder(),
                        )
                      : _coverPlaceholder(),
                ),
              ),
              const SizedBox(width: 14),

              // ─── Info ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      authorName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Genre chips
                    if (genre.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: genre
                            .split(',')
                            .take(2)
                            .map<Widget>(
                              (g) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  g.trim(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 6),

                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 13,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatCount(totalViews),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.favorite_border,
                          size: 13,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatCount(totalLikes),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.menu_book_outlined,
                          size: 13,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$episodesCount ep',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() => Container(
    width: 72,
    height: 100,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.auto_stories, size: 24, color: Colors.grey[400]),
  );

  String _formatCount(dynamic count) {
    final n = count is int ? count : int.tryParse(count.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Color _rankColor(int r) => switch (r) {
    1 => const Color(0xFFFFD700), // Gold
    2 => const Color(0xFFC0C0C0), // Silver
    3 => const Color(0xFFCD7F32), // Bronze
    _ => Colors.grey,
  };
}

// ─── Rank Badge Widget ───
class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: switch (rank) {
              1 => [const Color(0xFFFFD700), const Color(0xFFFFA500)],
              2 => [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)],
              3 => [const Color(0xFFCD7F32), const Color(0xFFA0522D)],
              _ => [Colors.grey, Colors.grey],
            },
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _color.withAlpha(60),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 30,
      child: Center(
        child: Text(
          '#$rank',
          style: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color get _color => switch (rank) {
    1 => const Color(0xFFFFD700),
    2 => const Color(0xFFC0C0C0),
    3 => const Color(0xFFCD7F32),
    _ => Colors.grey,
  };
}
