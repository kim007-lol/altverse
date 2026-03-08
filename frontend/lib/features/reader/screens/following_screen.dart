import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'author_profile_screen.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<dynamic> _authors = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchFollowing();
  }

  Future<void> _fetchFollowing() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final res = await ApiService.get(ApiEndpoints.following);
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        setState(() {
          _authors = body['data'] ?? [];
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

  Future<void> _toggleFollow(int userId, int index) async {
    try {
      final res = await ApiService.post(ApiEndpoints.followToggle(userId), {});
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final isNowFollowing = data['following'] ?? false;
        if (!isNowFollowing) {
          // Unfollowed — remove from list
          setState(() => _authors.removeAt(index));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unfollow berhasil'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengubah follow'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat data',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchFollowing,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_authors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Belum ada yang difollow',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Follow author favoritmu dari halaman series!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFollowing,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _authors.length,
        itemBuilder: (context, i) {
          final author = _authors[i];
          return _AuthorTile(
            id: author['id'] ?? 0,
            name: author['name'] ?? '',
            penName: author['pen_name'] ?? author['name'] ?? '',
            avatarUrl: author['avatar_url'],
            followersCount: author['followers_count'] ?? 0,
            seriesCount: author['series_count'] ?? 0,
            onUnfollow: () => _toggleFollow(author['id'], i),
          );
        },
      ),
    );
  }
}

class _AuthorTile extends StatelessWidget {
  final int id;
  final String name;
  final String penName;
  final String? avatarUrl;
  final int followersCount;
  final int seriesCount;
  final VoidCallback onUnfollow;

  const _AuthorTile({
    required this.id,
    required this.name,
    required this.penName,
    this.avatarUrl,
    required this.followersCount,
    required this.seriesCount,
    required this.onUnfollow,
  });

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imgUrl = avatarUrl != null ? ApiService.getImageUrl(avatarUrl) : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AuthorProfileScreen(authorId: id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.primaryColor.withAlpha(30),
              backgroundImage: imgUrl != null && imgUrl.isNotEmpty
                  ? NetworkImage(imgUrl)
                  : null,
              child: imgUrl == null || imgUrl.isEmpty
                  ? Icon(Icons.person, size: 28, color: theme.primaryColor)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    penName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatCount(followersCount)} followers',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.auto_stories,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$seriesCount series',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.grey[700],
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: Size.zero,
              ),
              onPressed: onUnfollow,
              child: const Text(
                'Following',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
