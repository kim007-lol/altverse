import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'author_profile_screen.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchSeries();
  }

  Future<void> _fetchSeries() async {
    try {
      final res = await ApiService.get(
        ApiEndpoints.seriesDetail(widget.seriesId),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['series'];
        if (mounted) {
          setState(() {
            _series = data;
            _isLiked = data['is_liked'] ?? false;
            _isBookmarked = data['is_bookmarked'] ?? false;
            _isFollowing = data['is_following'] ?? false;
            _isLoading = false;
            _hasError = false;
          });
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

  // ─── Toggle Like ───
  Future<void> _toggleLike() async {
    if (_series == null) return;
    final wasLiked = _isLiked;
    final oldCount = _series!['total_likes'] ?? 0;
    setState(() {
      _isLiked = !wasLiked;
      _series!['total_likes'] = wasLiked
          ? (oldCount > 0 ? oldCount - 1 : 0)
          : oldCount + 1;
    });
    try {
      final res = await ApiService.post(
        ApiEndpoints.likeToggle(widget.seriesId),
        {},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _isLiked = data['liked'] ?? _isLiked;
            _series!['total_likes'] =
                data['total_likes'] ?? _series!['total_likes'];
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
  }

  // ─── Toggle Bookmark ───
  Future<void> _toggleBookmark() async {
    if (_series == null) return;
    final was = _isBookmarked;
    setState(() => _isBookmarked = !was);
    try {
      final res = await ApiService.post(
        ApiEndpoints.bookmarkToggle(widget.seriesId),
        {},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() => _isBookmarked = data['bookmarked'] ?? !was);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBookmarked ? 'Bookmark ditambahkan' : 'Bookmark dihapus',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      } else if (mounted) {
        setState(() => _isBookmarked = was);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengubah bookmark'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isBookmarked = was);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: gagal mengubah bookmark'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Toggle Follow Author ───
  Future<void> _toggleFollow() async {
    if (_series == null) return;
    final authorId = _series!['author']?['id'];
    if (authorId == null) return;
    final was = _isFollowing;
    setState(() => _isFollowing = !was);
    try {
      final res = await ApiService.post(
        ApiEndpoints.followToggle(authorId),
        {},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() => _isFollowing = data['following'] ?? _isFollowing);
        }
      } else {
        if (mounted) setState(() => _isFollowing = was);
      }
    } catch (_) {
      if (mounted) setState(() => _isFollowing = was);
    }
  }

  // ─── Support / Donate ───
  void _showSupportDialog() {
    if (_series == null) return;
    final authorId = _series!['author']?['id'];
    final authorName =
        _series!['author']?['pen_name'] ??
        _series!['author']?['name'] ??
        'Author';
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
                prefixIcon: const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [5, 10, 25, 50, 100].map((amt) {
                return ActionChip(
                  label: Text('$amt'),
                  avatar: const Icon(
                    Icons.monetization_on,
                    size: 16,
                    color: Colors.amber,
                  ),
                  onPressed: () => amountController.text = '$amt',
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
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
      final res = await ApiService.post(ApiEndpoints.tip, {
        'recipient_id': authorId,
        'amount': amount,
      });
      if (mounted) {
        final msg = res.statusCode == 200
            ? jsonDecode(res.body)['message'] ?? 'Tip berhasil dikirim! 🎉'
            : jsonDecode(res.body)['message'] ?? 'Gagal mengirim tip';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: res.statusCode == 200 ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error mengirim tip'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareSeries() {
    if (_series == null) return;
    final title = _series!['title'] ?? 'Series';
    final slug = _series!['slug'] ?? '';
    // ignore: deprecated_member_use
    Share.share(
      'Check out "$title" on AU Reader!\nhttps://aureader.com/series/$slug',
      subject: title,
    );
  }

  // ─── Helpers ───
  String _formatCount(dynamic count) {
    final n = count is int ? count : int.tryParse(count.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
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
    final episodes = _series!['episodes'] as List? ?? [];
    final author = _series!['author'] ?? {};
    final authorName = author['pen_name'] ?? author['name'] ?? 'Unknown';
    final authorAvatar = author['avatar_url'] != null
        ? ApiService.getImageUrl(author['avatar_url'])
        : null;
    final synopsis = _series!['synopsis'] ?? 'No synopsis available.';
    final genre = _series!['genre'] ?? '';
    final ageRating = _series!['age_rating'] ?? '';
    final followersCount =
        _series!['followers_count'] ?? author['followers_count'] ?? 0;

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
                          child: const Icon(
                            Icons.auto_stories,
                            size: 64,
                            color: Colors.white38,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (ctx1, url1) =>
                              Container(color: Colors.grey[300]),
                          errorWidget: (ctx2, url2, err) => Container(
                            color: theme.primaryColor.withAlpha(40),
                            child: const Icon(
                              Icons.auto_stories,
                              size: 64,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(30),
                          Colors.black.withAlpha(180),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
                onPressed: _toggleBookmark,
                tooltip: 'Bookmark',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) {
                  if (val == 'share') _shareSeries();
                  if (val == 'report') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report sent. Thank you!')),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Share'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: ListTile(
                      leading: Icon(Icons.flag_outlined),
                      title: Text('Report'),
                    ),
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
                              MaterialPageRoute(
                                builder: (_) =>
                                    AuthorProfileScreen(authorId: authorId),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: authorAvatar != null
                              ? CachedNetworkImageProvider(authorAvatar)
                              : null,
                          child: authorAvatar == null
                              ? const Icon(Icons.person, size: 22)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '$followersCount followers',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Follow Button
                      FilledButton.icon(
                        onPressed: _toggleFollow,
                        icon: Icon(
                          _isFollowing ? Icons.check : Icons.person_add_alt_1,
                          size: 16,
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
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                          icon: _isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          label: _formatCount(_series!['total_likes'] ?? 0),
                          color: _isLiked ? Colors.red : Colors.grey[700]!,
                          onTap: _toggleLike,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Support / Donate Button
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.volunteer_activism,
                          label: 'Support',
                          color: Colors.pink[400]!,
                          onTap: _showSupportDialog,
                        ),
                      ),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
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
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        _StatChip(
                          icon: Icons.list_alt,
                          value: '${episodes.length}',
                          label: 'Episodes',
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
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
                  const Text(
                    'Synopsis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _synopsisExpanded = !_synopsisExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          synopsis,
                          maxLines: _synopsisExpanded ? 100 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        if (synopsis.length > 100)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _synopsisExpanded ? 'Show less' : 'Read more...',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
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
                                label: Text(
                                  g.trim(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: theme.primaryColor.withAlpha(
                                  25,
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                      if (ageRating.isNotEmpty)
                        Chip(
                          label: Text(
                            ageRating,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.orange.withAlpha(30),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── Episodes Header ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Episodes (${episodes.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada episode',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final ep = episodes[index];
                    final bool isPremium = ep['is_premium'] == true;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withAlpha(30)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReadingScreen(
                                seriesId: widget.seriesId,
                                episodeId: ep['id'],
                              ),
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
                              // Episode number badge
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
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
                                      ep['title'] ??
                                          'Episode ${ep['episode_number']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (ep['created_at'] != null)
                                      Text(
                                        _formatDate(ep['created_at']),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Comment icon
                              IconButton(
                                icon: Icon(
                                  Icons.comment_outlined,
                                  size: 18,
                                  color: Colors.grey[500],
                                ),
                                onPressed: () =>
                                    CommentDrawer.show(context, ep['id']),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Comments',
                              ),
                              const SizedBox(width: 4),
                              // Lock or chevron
                              if (isPremium)
                                Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Colors.orange[400],
                                )
                              else
                                Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: Colors.grey[400],
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: episodes.length),
                ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
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

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
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

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }
}
