import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/api_service.dart';
import '../widgets/comment_drawer.dart'; // the actual path we used
import 'package:cached_network_image/cached_network_image.dart';

class ReadingScreen extends StatefulWidget {
  final int seriesId;
  final int episodeId;

  const ReadingScreen({
    super.key,
    required this.seriesId,
    required this.episodeId,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showToolbar = true;
  bool _darkMode = false;

  bool _isLoading = true;
  bool _isLocked = false;
  Map<String, dynamic>? _episode;
  List<dynamic> _pages = [];

  // Episode like state
  bool _isEpisodeLiked = false;
  int _episodeLikeCount = 0;

  // Prefetch settings
  final int _prefetchAhead = 2;
  final int _prefetchBehind = 1;
  final Set<int> _prefetchedIndices = {};

  @override
  void initState() {
    super.initState();
    _fetchEpisodePages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchEpisodePages() async {
    try {
      final res = await ApiService.get(
        ApiEndpoints.readEpisode(widget.seriesId, widget.episodeId),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _isLocked = data['locked'] ?? false;
            _episode = data['episode'];
            _isEpisodeLiked = data['is_liked'] ?? false;
            _episodeLikeCount = data['like_count'] ?? 0;
            if (_isLocked) {
              _pages = data['preview_pages'] ?? [];
            } else {
              _pages = _episode?['pages'] ?? [];
            }
            _isLoading = false;
          });
          if (_pages.isNotEmpty) {
            _prefetchAround(0);
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProgress(int pageIndex) async {
    if (_isLocked || _pages.isEmpty) return;
    final progress = ((pageIndex + 1) / _pages.length) * 100;

    try {
      await ApiService.post(
        ApiEndpoints.updateProgress(widget.seriesId, widget.episodeId),
        {'last_page': pageIndex + 1, 'progress': progress},
      );
    } catch (_) {}
  }

  void _prefetchAround(int index) {
    if (!mounted || _pages.isEmpty) return;

    final start = max(0, index - _prefetchBehind);
    final end = min(_pages.length - 1, index + _prefetchAhead);

    for (int i = start; i <= end; i++) {
      if (!_prefetchedIndices.contains(i)) {
        final url = ApiService.getImageUrl(_pages[i]['image_path']);
        if (url.isNotEmpty) {
          precacheImage(CachedNetworkImageProvider(url), context);
          _prefetchedIndices.add(i);
        }
      }
    }

    // In a full implementation, we would evict images outside this window from cache.
    // For Flutter's DefaultCacheManager (CachedNetworkImage), LRU handles it pretty well.
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    if (index < _pages.length) {
      _prefetchAround(index);
      _updateProgress(index);
    }
  }

  Future<void> _unlockEpisode() async {
    try {
      final res = await ApiService.post(
        ApiEndpoints.episodeUnlock(widget.episodeId),
        {},
      );
      if (res.statusCode == 200) {
        // Success, reload
        setState(() {
          _isLoading = true;
          _prefetchedIndices.clear();
        });
        _fetchEpisodePages();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonDecode(res.body)['message'] ?? 'Unlock failed'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error unlocking episode')),
        );
      }
    }
  }

  Future<void> _toggleEpisodeLike() async {
    final wasLiked = _isEpisodeLiked;
    // Optimistic update
    setState(() {
      _isEpisodeLiked = !wasLiked;
      _episodeLikeCount += wasLiked ? -1 : 1;
    });

    try {
      final res = await ApiService.post(
        ApiEndpoints.episodeLikeToggle(widget.seriesId, widget.episodeId),
        {},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _isEpisodeLiked = data['liked'] ?? _isEpisodeLiked;
            _episodeLikeCount = data['like_count'] ?? _episodeLikeCount;
          });
        }
      } else {
        // Revert
        if (mounted) {
          setState(() {
            _isEpisodeLiked = wasLiked;
            _episodeLikeCount += wasLiked ? 1 : -1;
          });
        }
      }
    } catch (_) {
      // Revert
      if (mounted) {
        setState(() {
          _isEpisodeLiked = wasLiked;
          _episodeLikeCount += wasLiked ? 1 : -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_episode == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Failed to load episode')),
      );
    }

    final bg = _darkMode ? const Color(0xFF1A1A2E) : Colors.white;
    final fg = _darkMode ? Colors.white : Colors.black87;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => _showToolbar = !_showToolbar),
          child: Stack(
            children: [
              // ─── Page Content (Swipe Horizontal) ───
              PageView.builder(
                controller: _pageController,
                itemCount: _pages.length + 1, // +1 for end page or paywall
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) {
                  if (i == _pages.length) {
                    if (_isLocked) return _buildPaywallPage(theme);
                    return _buildEndPage(theme);
                  }
                  return _buildImagePage(i);
                },
              ),

              // ─── Top Toolbar ───
              if (_showToolbar)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [bg, bg.withAlpha(0)],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: fg),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                _episode!['title'] ?? 'Episode',
                                style: TextStyle(
                                  color: fg,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _currentPage < _pages.length
                                    ? 'Page ${_currentPage + 1} / ${_pages.length}'
                                    : 'End',
                                style: TextStyle(
                                  color: fg.withAlpha(178),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.more_vert, color: fg),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),

              // ─── Bottom Toolbar ───
              if (_showToolbar)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [bg, bg.withAlpha(0)],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _toolButton(
                              icon: _isEpisodeLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              label: '$_episodeLikeCount',
                              fg: _isEpisodeLiked ? Colors.red : fg,
                              onTap: _toggleEpisodeLike,
                            ),
                            _toolButton(
                              icon: Icons.comment_outlined,
                              label: 'Comments',
                              fg: fg,
                              onTap: () =>
                                  CommentDrawer.show(context, widget.episodeId),
                            ),
                            _toolButton(
                              icon: _darkMode
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              label: _darkMode ? 'Light' : 'Dark',
                              fg: fg,
                              onTap: () =>
                                  setState(() => _darkMode = !_darkMode),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // ─── Comments FAB (always visible) ───
              Positioned(
                bottom: _showToolbar ? 80 : 24,
                right: 24,
                child: FloatingActionButton(
                  onPressed: () {
                    CommentDrawer.show(context, widget.episodeId);
                  },
                  backgroundColor: theme.primaryColor,
                  child: const Icon(Icons.comment, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePage(int index) {
    final pageConfig = _pages[index];
    final url = ApiService.getImageUrl(pageConfig['image_path']);

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 3.0,
      child: Center(
        child: url.isEmpty
            ? const Icon(Icons.broken_image, size: 64, color: Colors.grey)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPaywallPage(ThemeData theme) {
    final coinsRequired = _episode!['coin_price'] ?? 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Episode Locked',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock this episode to continue reading.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _unlockEpisode,
              child: Text(
                'Unlock for $coinsRequired Coins',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndPage(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'End of Episode',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You finished this episode!',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Back to Series',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String label,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: fg, fontSize: 10)),
        ],
      ),
    );
  }
}
