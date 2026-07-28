// series_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'author_profile_screen.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/debouncer.dart';
import '../../shared/widgets/report_dialog.dart';
import '../widgets/comment_drawer.dart';
import 'reading_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SeriesDetailScreen extends StatefulWidget {
  final int seriesId;

  const SeriesDetailScreen({super.key, required this.seriesId});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _series;
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _isFollowing = false;
  bool _synopsisExpanded = false;

  // Paginated episodes state
  final List<Map<String, dynamic>> _episodes = [];
  bool _isLoadingEpisodes = false;
  bool _hasMoreEpisodes = true;
  int _episodePage = 1;

  // Action guards
  final ActionGuard _likeGuard = ActionGuard();
  final ActionGuard _bookmarkGuard = ActionGuard();
  final ActionGuard _followGuard = ActionGuard();

  @override
  void initState() {
    super.initState();
    _fetchSeries();
  }

  Future<void> _fetchSeries() async {
    try {
      final res = await ApiService.get(ApiEndpoints.seriesDetail(widget.seriesId));
      if (res.success) {
        final data = res.data['series'];
        if (mounted) {
          setState(() {
            _series = data;
            _isLiked = data['is_liked'] ?? false;
            _isBookmarked = data['is_bookmarked'] ?? false;
            _isFollowing = data['is_following'] ?? false;
            _isLoading = false;
            _hasError = false;
          });
          // Load first page of episodes
          _loadEpisodes();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadEpisodes() async {
    if (_isLoadingEpisodes || !_hasMoreEpisodes) return;
    setState(() => _isLoadingEpisodes = true);

    try {
      final res = await ApiService.get(
        'reader/series/${widget.seriesId}/episodes',
        queryParams: {'page': '$_episodePage'},
      );
      if (res.success && mounted) {
        final data = res.data;
        final List items = data['data'] ?? [];
        final int lastPage = (data['meta'] as Map?)?['last_page'] ?? 1;
        setState(() {
          _episodes.addAll(items.map((e) => Map<String, dynamic>.from(e)).toList());
          _hasMoreEpisodes = _episodePage < lastPage;
          _episodePage++;
          _isLoadingEpisodes = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingEpisodes = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEpisodes = false);
    }
  }

  // ─── Toggle Like ───
  Future<void> _toggleLike() async {
    if (_series == null) return;
    _likeGuard.run(() async {
      final wasLiked = _isLiked;
      final oldCount = _series!['total_likes'] ?? 0;
      setState(() {
        _isLiked = !wasLiked;
        _series!['total_likes'] = wasLiked ? (oldCount > 0 ? oldCount - 1 : 0) : oldCount + 1;
      });
      try {
        final res = await ApiService.post(ApiEndpoints.likeToggle(widget.seriesId), body: {});
        if (res.success) {
          final data = res.data;
          if (mounted) {
            setState(() {
              _isLiked = data['liked'] ?? _isLiked;
              _series!['total_likes'] = data['total_likes'] ?? _series!['total_likes'];
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLiked = wasLiked;
              _series!['total_likes'] = oldCount;
            });
          }
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLiked = wasLiked;
            _series!['total_likes'] = oldCount;
          });
        }
      }
    });
  }

  // ─── Toggle Bookmark ───
  Future<void> _toggleBookmark() async {
    if (_series == null) return;
    _bookmarkGuard.run(() async {
      final was = _isBookmarked;
      setState(() => _isBookmarked = !was);
      try {
        final res = await ApiService.post(ApiEndpoints.bookmarkToggle(widget.seriesId), body: {});
        if (res.success && mounted) {
          final data = res.data;
          setState(() => _isBookmarked = data['bookmarked'] ?? !was);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isBookmarked ? 'Bookmark ditambahkan' : 'Bookmark dihapus'),
              duration: const Duration(seconds: 1),
            ),
          );
        } else if (mounted) {
          setState(() => _isBookmarked = was);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Gagal mengubah bookmark'), backgroundColor: Colors.red));
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isBookmarked = was);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Error: gagal mengubah bookmark'), backgroundColor: Colors.red));
        }
      }
    });
  }

  // ─── Toggle Follow Author ───
  Future<void> _toggleFollow() async {
    if (_series == null) return;
    _followGuard.run(() async {
      final authorId = _series!['author']?['id'];
      if (authorId == null) return;
      final was = _isFollowing;
      setState(() => _isFollowing = !was);
      try {
        final res = await ApiService.post(ApiEndpoints.followToggle(authorId), body: {});
        if (res.success) {
          final data = res.data;
          if (mounted) {
            setState(() => _isFollowing = data['following'] ?? _isFollowing);
          }
        } else {
          if (mounted) setState(() => _isFollowing = was);
        }
      } catch (_) {
        if (mounted) setState(() => _isFollowing = was);
      }
    });
  }

  // ─── Support / Donate ───
  void _showSupportDialog() {
    if (_series == null) return;
    final authorId = _series!['author']?['id'];
    final authorName = _series!['author']?['pen_name'] ?? _series!['author']?['name'] ?? 'Author';
    if (authorId == null) return;

    final amountController = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.volunteer_activism, color: Colors.pink[400]),
            const SizedBox(width: 8),
            Text('Support $authorName'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kirim coins sebagai dukungan untuk author ini!'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Jumlah Coins',
                prefixIcon: const Icon(Icons.monetization_on, color: Colors.amber),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [5, 10, 25, 50, 100].map((amt) {
                return ActionChip(
                  label: Text('$amt'),
                  avatar: const Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                  onPressed: () => amountController.text = '$amt',
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton.icon(
            onPressed: () async {
              final amount = int.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              Navigator.pop(ctx);
              _sendTip(authorId, amount);
            },
            icon: const Icon(Icons.send),
            label: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTip(int authorId, int amount) async {
    try {
      final res = await ApiService.post(ApiEndpoints.tip, body: {'author_id': authorId, 'amount': amount});
      if (mounted) {
        final msg = res.success
            ? (res.data is Map ? res.data['message'] ?? 'Tip berhasil dikirim! 🎉' : 'Tip berhasil dikirim! 🎉')
            : res.message;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: res.success ? Colors.green : Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error mengirim tip'), backgroundColor: Colors.red));
      }
    }
  }

  // ─── Episode Tap Handler ───
  void _onEpisodeTap(Map<String, dynamic> ep, bool isLocked, bool isOwnSeries, int coinPrice) {
    if (isOwnSeries && ep['is_premium'] == true) {
      // Author tapping own premium episode — navigate directly (they have free access via ReadingScreen)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReadingScreen(seriesId: widget.seriesId, episodeId: ep['id']),
        ),
      );
      return;
    }

    if (!isLocked) {
      // Free or already unlocked — navigate directly
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReadingScreen(seriesId: widget.seriesId, episodeId: ep['id']),
        ),
      );
      return;
    }

    // Locked — show unlock dialog
    final userCoins = _series?['user_coins'] ?? 0;
    final hasEnough = userCoins >= coinPrice;
    final episodeTitle = ep['title'] ?? 'Episode ${ep['episode_number']}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange[400]),
            const SizedBox(width: 8),
            const Expanded(child: Text('Episode Premium', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withAlpha(40)),
              ),
              child: Column(
                children: [
                  Text(
                    episodeTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, size: 28, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        '$coinPrice Coins',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Saldo kamu: $userCoins Coins',
                  style: TextStyle(
                    fontSize: 13,
                    color: hasEnough ? Colors.grey[600] : Colors.red,
                    fontWeight: hasEnough ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (!hasEnough) ...[
              const SizedBox(height: 8),
              Text(
                'Koin tidak cukup! Silakan top-up terlebih dahulu.',
                style: TextStyle(fontSize: 12, color: Colors.red[400]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton.icon(
            onPressed: hasEnough
                ? () {
                    Navigator.pop(ctx);
                    _performUnlock(ep['id'], coinPrice);
                  }
                : null,
            icon: const Icon(Icons.lock_open, size: 18),
            label: Text(hasEnough ? 'Unlock & Baca' : 'Koin Tidak Cukup'),
            style: FilledButton.styleFrom(
              backgroundColor: hasEnough ? Colors.orange : Colors.grey[300],
              foregroundColor: hasEnough ? Colors.white : Colors.grey[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performUnlock(int episodeId, int coinPrice) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await ApiService.post(ApiEndpoints.episodeUnlock(episodeId), body: {});

      if (!mounted) return;
      Navigator.pop(context); // close loading

      if (res.success) {
        // Update local user_coins
        setState(() {
          _series?['user_coins'] = (_series?['user_coins'] ?? 0) - coinPrice;
          // Mark episode as unlocked in local _episodes state
          for (var ep in _episodes) {
            if (ep['id'] == episodeId) {
              ep['is_unlocked'] = true;
              break;
            }
          }
        });

        // Refresh AuthProvider coins
        if (mounted) {
          context.read<AuthProvider>().refreshProfile();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? 'Episode berhasil di-unlock! 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to reading screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReadingScreen(seriesId: widget.seriesId, episodeId: episodeId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal unlock episode. Coba lagi.'), backgroundColor: Colors.red));
      }
    }
  }

  void _shareSeries() {
    if (_series == null) return;
    final title = _series!['title'] ?? 'Series';
    final slug = _series!['slug'] ?? '';
    // ignore: deprecated_member_use
    Share.share('Check out "$title" on AU Reader!\nhttps://aureader.com/series/$slug', subject: title);
  }

  // ─── Helpers ───
  String _formatCount(dynamic count) {
    final n = count is int ? count : int.tryParse(count.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  /// Determines the label, icon, and color for a given source URL
  ({String label, IconData icon, Color color}) _getSourceInfo(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('wattpad.com')) {
      return (label: 'Read on Wattpad', icon: Icons.auto_stories_outlined, color: const Color(0xFFFF6122));
    } else if (lower.contains('docs.google.com')) {
      return (label: 'Open Google Docs', icon: Icons.description_outlined, color: const Color(0xFF4285F4));
    } else if (lower.contains('medium.com')) {
      return (label: 'Read on Medium', icon: Icons.article_outlined, color: const Color(0xFF00AB6C));
    } else {
      return (label: 'Open Source Link', icon: Icons.link, color: Colors.blueGrey);
    }
  }

  Widget _buildSourceLinkButton(String url, ThemeData theme) {
    final info = _getSourceInfo(url);
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Gagal membuka link: $e'), backgroundColor: Colors.red));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: info.color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: info.color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: info.color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
              child: Icon(info.icon, color: info.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.label,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: info.color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Uri.tryParse(url)?.host ?? url,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 18, color: info.color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasError || _series == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text('Failed to load series'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _fetchSeries();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final String coverUrl = ApiService.getImageUrl(_series!['cover_url']);
    final episodes = _episodes;
    final author = _series!['author'] ?? {};
    final authorName = author['pen_name'] ?? 'Unknown';
    final authorAvatar = author['author_avatar_url'] != null
        ? ApiService.getImageUrl(author['author_avatar_url'])
        : null;
    final synopsis = _series!['synopsis'] ?? 'No synopsis available.';
    final genre = _series!['genre'] ?? '';
    final ageRating = _series!['age_rating'] ?? '';
    final followersCount = _series!['followers_count'] ?? author['followers_count'] ?? 0;

    // Check if current user is the author of this series
    final currentUserId = context.watch<AuthProvider>().user?['id'];
    final isOwnSeries = currentUserId != null && author['id'] == currentUserId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ═══════════════════════════════════════
          // TOP BAR: ← | Series title | ⋮
          // ═══════════════════════════════════════
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _series!['title'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover big
                  coverUrl.isEmpty
                      ? Container(
                          color: theme.primaryColor.withAlpha(40),
                          child: const Icon(Icons.auto_stories, size: 64, color: Colors.white38),
                        )
                      : CachedNetworkImage(
                          imageUrl: coverUrl,
                          memCacheWidth: 800,
                          fit: BoxFit.cover,
                          placeholder: (ctx1, url1) => Container(color: Colors.grey[300]),
                          errorWidget: (ctx2, url2, err) => Container(
                            color: theme.primaryColor.withAlpha(40),
                            child: const Icon(Icons.auto_stories, size: 64, color: Colors.white38),
                          ),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withAlpha(30), Colors.black.withAlpha(180)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                onPressed: _toggleBookmark,
                tooltip: 'Bookmark',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) {
                  if (val == 'share') _shareSeries();
                  if (val == 'report') {
                    ReportDialog.show(context, targetType: 'series', targetId: widget.seriesId);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(leading: Icon(Icons.share), title: Text('Share')),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: ListTile(leading: Icon(Icons.flag_outlined), title: Text('Report')),
                  ),
                ],
              ),
            ],
          ),

          // ═══════════════════════════════════════
          // BODY
          // ═══════════════════════════════════════
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Author Row: Avatar + Name + Follow ───
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final authorId = author['id'];
                          if (authorId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AuthorProfileScreen(authorId: authorId)),
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: authorAvatar != null ? CachedNetworkImageProvider(authorAvatar) : null,
                          child: authorAvatar == null ? const Icon(Icons.person, size: 22) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('$followersCount followers', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                      // Follow Button (hide if own series)
                      if (!isOwnSeries)
                        FilledButton.icon(
                          onPressed: _toggleFollow,
                          icon: Icon(_isFollowing ? Icons.check : Icons.person_add_alt_1, size: 16),
                          label: Text(_isFollowing ? 'Following' : 'Follow'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _isFollowing ? Colors.grey[300] : theme.primaryColor,
                            foregroundColor: _isFollowing ? Colors.grey[700] : theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── Action Buttons Row: Like • Support • Share ───
                  Row(
                    children: [
                      // Like Button
                      Expanded(
                        child: _ActionButton(
                          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                          label: _formatCount(_series!['total_likes'] ?? 0),
                          color: _isLiked ? Colors.red : Colors.grey[700]!,
                          onTap: _toggleLike,
                        ),
                      ),
                      // Support / Donate Button (hide if own series)
                      if (!isOwnSeries) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.volunteer_activism,
                            label: 'Support',
                            color: Colors.pink[400]!,
                            onTap: _showSupportDialog,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Share Button
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          color: Colors.blue[600]!,
                          onTap: _shareSeries,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── Stats Row: views • episodes • last updated ───
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatChip(
                          icon: Icons.visibility_outlined,
                          value: _formatCount(_series!['total_views'] ?? 0),
                          label: 'Views',
                        ),
                        Container(width: 1, height: 30, color: Colors.grey[300]),
                        _StatChip(icon: Icons.list_alt, value: '${episodes.length}', label: 'Episodes'),
                        Container(width: 1, height: 30, color: Colors.grey[300]),
                        _StatChip(
                          icon: Icons.favorite,
                          value: _formatCount(_series!['total_likes'] ?? 0),
                          label: 'Likes',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Synopsis (expandable) ───
                  const Text('Synopsis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _synopsisExpanded = !_synopsisExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          synopsis,
                          maxLines: _synopsisExpanded ? 100 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                        ),
                        if (synopsis.length > 100)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _synopsisExpanded ? 'Show less' : 'Read more...',
                              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Tags: genre, age_rating ───
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (genre.isNotEmpty)
                        ...genre
                            .split(',')
                            .map(
                              (g) => Chip(
                                label: Text(g.trim(), style: const TextStyle(fontSize: 12)),
                                backgroundColor: theme.primaryColor.withAlpha(25),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                      if (ageRating.isNotEmpty)
                        Chip(
                          label: Text(ageRating, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.orange.withAlpha(30),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ─── Source / Wattpad Link ───
                  if ((_series!['source_url'] ?? '').toString().isNotEmpty)
                    _buildSourceLinkButton(_series!['source_url'], theme),

                  const SizedBox(height: 20),

                  // ─── Episodes Header ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Episodes (${_series!['episode_count'] ?? episodes.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════
          // EPISODE LIST
          // ═══════════════════════════════════════
          episodes.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('Belum ada episode', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final ep = episodes[index];
                    final bool isPremium = ep['is_premium'] == true;
                    final bool isUnlocked = ep['is_unlocked'] == true;
                    final bool isLocked = isPremium && !isUnlocked && !isOwnSeries;
                    final int coinPrice = ep['coin_price'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isLocked ? Colors.orange.withAlpha(60) : Colors.grey.withAlpha(50)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _onEpisodeTap(ep, isLocked, isOwnSeries, coinPrice),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              // Episode number badge
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isLocked ? Colors.orange.withAlpha(20) : theme.primaryColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: isLocked
                                      ? Icon(Icons.lock, size: 18, color: Colors.orange[400])
                                      : Text(
                                          '${ep['episode_number'] ?? index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Title
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ep['title'] ?? 'Episode ${ep['episode_number']}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (ep['created_at'] != null)
                                      Text(
                                        _formatDate(ep['created_at']),
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                      ),
                                  ],
                                ),
                              ),
                              // Coin price badge for locked episodes
                              if (isLocked) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.withAlpha(60)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$coinPrice',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              // Comment icon
                              if (!isLocked)
                                IconButton(
                                  icon: Icon(Icons.comment_outlined, size: 18, color: Colors.grey[500]),
                                  onPressed: () => CommentDrawer.show(context, ep['id']),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Comments',
                                ),
                              const SizedBox(width: 4),
                              // Lock or chevron
                              if (isPremium && isOwnSeries)
                                Icon(Icons.lock_open, size: 16, color: Colors.green[400])
                              else if (isPremium && isUnlocked)
                                Icon(Icons.check_circle, size: 16, color: Colors.green[400])
                              else if (!isPremium)
                                Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: episodes.length),
                ),

          // ─── Load More / Loading Indicator ───
          if (_hasMoreEpisodes || _isLoadingEpisodes)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: _isLoadingEpisodes
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton.icon(
                          onPressed: _loadEpisodes,
                          icon: const Icon(Icons.expand_more),
                          label: const Text('Muat episode lainnya'),
                        ),
                ),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─── Action Button Widget ───
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Chip Widget ───
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }
}
