import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../shared/widgets/au_card.dart';
import 'series_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Bookmarks (Saved Series)
  List<dynamic> _bookmarks = [];
  bool _bookmarksLoading = true;

  // History (Continue Reading)
  List<dynamic> _history = [];
  bool _historyLoading = true;

  // Unlocked (Purchased Episodes)
  List<dynamic> _unlocked = [];
  bool _unlockedLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchHistory();
    _fetchBookmarks();
    _fetchUnlocked();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookmarks() async {
    if (!mounted) return;
    setState(() => _bookmarksLoading = true);
    try {
      final res = await ApiService.get(ApiEndpoints.bookmarks);
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        setState(() {
          _bookmarks = body['data'] ?? [];
          _bookmarksLoading = false;
        });
      } else if (mounted) {
        setState(() => _bookmarksLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _bookmarksLoading = false);
    }
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() => _historyLoading = true);
    try {
      final res = await ApiService.get(ApiEndpoints.readingHistory);
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        setState(() {
          _history = body['data'] ?? [];
          _historyLoading = false;
        });
      } else if (mounted) {
        setState(() => _historyLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _fetchUnlocked() async {
    if (!mounted) return;
    setState(() => _unlockedLoading = true);
    try {
      final res = await ApiService.get(ApiEndpoints.unlockedEpisodes);
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        setState(() {
          _unlocked = body['data'] ?? [];
          _unlockedLoading = false;
        });
      } else if (mounted) {
        setState(() => _unlockedLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _unlockedLoading = false);
    }
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'My Library',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.displayLarge?.color,
                ),
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: theme.primaryColor,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Continue'),
                Tab(text: 'Saved'),
                Tab(text: 'Unlocked'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryTab(theme),
                  _buildBookmarksTab(theme),
                  _buildUnlockedTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── History (Continue Reading) Tab ───
  Widget _buildHistoryTab(ThemeData theme) {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return _buildEmptyState(
        'Belum ada riwayat',
        'Mulai baca series untuk melanjutkan progress-mu!',
        Icons.menu_book_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _history.length,
        itemBuilder: (context, i) {
          final item = _history[i];
          final series = item['series'];
          final episode = item['episode'];
          final author = series?['author'];
          final authorName = author?['pen_name'] ?? 'Unknown';
          final coverUrl = ApiService.getImageUrl(series?['cover_url']);
          final timeAgo = _formatTimeAgo(item['read_at']);
          final epTitle =
              episode?['title'] ??
              'Episode ${episode?['episode_number'] ?? ''}';

          return SeriesListCard(
            title: series?['title'] ?? 'Untitled',
            author: authorName,
            coverUrl: coverUrl,
            subtitle: '$epTitle • $timeAgo',
            onTap: () {
              final seriesId = series?['id'];
              if (seriesId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeriesDetailScreen(seriesId: seriesId),
                  ),
                ).then((_) {
                  if (mounted) _fetchHistory();
                });
              }
            },
          );
        },
      ),
    );
  }

  // ─── Bookmarks (Saved Series) Tab ───
  Widget _buildBookmarksTab(ThemeData theme) {
    if (_bookmarksLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_bookmarks.isEmpty) {
      return _buildEmptyState(
        'Belum ada serial tersimpan',
        'Bookmark series favoritmu agar mudah ditemukan!',
        Icons.bookmark_border_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBookmarks,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _bookmarks.length,
        itemBuilder: (context, i) {
          final series = _bookmarks[i];
          final author = series['author'];
          final authorName = author?['pen_name'] ?? 'Unknown';
          final coverUrl = ApiService.getImageUrl(series['cover_url']);
          final rawGenre = series['genre'];
          final List<String> genres;
          if (rawGenre is List) {
            genres = rawGenre.map((g) => g.toString()).toList();
          } else if (rawGenre is String && rawGenre.isNotEmpty) {
            genres = rawGenre.split(',').map((g) => g.trim()).toList();
          } else {
            genres = <String>[];
          }
          final epCount = series['episodes_count'] ?? 0;

          return SeriesListCard(
            title: series['title'] ?? 'Untitled',
            author: authorName,
            coverUrl: coverUrl,
            genres: genres,
            subtitle: '$epCount episodes',
            onTap: () {
              final seriesId = series['id'];
              if (seriesId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeriesDetailScreen(seriesId: seriesId),
                  ),
                ).then((_) {
                  if (mounted) _fetchBookmarks();
                });
              }
            },
          );
        },
      ),
    );
  }

  // ─── Unlocked (Purchased Episodes) Tab ───
  Widget _buildUnlockedTab(ThemeData theme) {
    if (_unlockedLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_unlocked.isEmpty) {
      return _buildEmptyState(
        'Belum ada episode di-unlock',
        'Episode berbayar yang kamu beli dengan koin akan muncul di sini.',
        Icons.lock_open_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUnlocked,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _unlocked.length,
        itemBuilder: (context, i) {
          final episode = _unlocked[i];
          final series = episode['series'];
          final author = series?['author'];
          final authorName = author?['pen_name'] ?? 'Unknown';
          final coverUrl = ApiService.getImageUrl(series?['cover_url']);

          final epTitle =
              episode['title'] ?? 'Episode ${episode['episode_number'] ?? ''}';
          final coinPrice = episode['coin_price'] ?? 0;

          return SeriesListCard(
            title: series?['title'] ?? 'Untitled',
            author: authorName,
            coverUrl: coverUrl,
            subtitle: '$epTitle • $coinPrice Coins',
            onTap: () {
              final seriesId = series?['id'];
              if (seriesId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeriesDetailScreen(seriesId: seriesId),
                  ),
                ).then((_) {
                  if (mounted) _fetchUnlocked();
                });
              }
            },
          );
        },
      ),
    );
  }

  // ─── Empty State ───
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
