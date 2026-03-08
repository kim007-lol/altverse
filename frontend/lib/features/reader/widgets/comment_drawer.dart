import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/reader_profile_screen.dart';
import '../screens/author_profile_screen.dart';

class CommentDrawer extends StatefulWidget {
  final int episodeId;

  const CommentDrawer({super.key, required this.episodeId});

  static void show(BuildContext context, int episodeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentDrawer(episodeId: episodeId),
    );
  }

  @override
  State<CommentDrawer> createState() => _CommentDrawerState();
}

class _CommentDrawerState extends State<CommentDrawer> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _comments = [];
  String _sort = 'top';

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    try {
      final endpoint =
          '${ApiEndpoints.episodeComments(widget.episodeId)}?sort=$_sort';
      final res = await ApiService.get(endpoint);
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _comments = jsonDecode(res.body)['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        debugPrint('Comment fetch error: ${res.statusCode} ${res.body}');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Comment fetch exception: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.post(
        ApiEndpoints.episodeComments(widget.episodeId),
        {'body': text},
      );

      if (res.statusCode == 201) {
        _commentController.clear();
        _fetchComments();
      } else {
        final error =
            jsonDecode(res.body)['message'] ?? 'Failed to post comment';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    } catch (e) {
      debugPrint('Post comment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error posting comment')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleLike(int index) async {
    final comment = _comments[index];
    final commentId = comment['id'];
    final isLiked = comment['is_liked'] == true;

    // Optimistic update
    setState(() {
      comment['is_liked'] = !isLiked;
      comment['likes_count'] =
          (comment['likes_count'] ?? 0) + (isLiked ? -1 : 1);
    });

    try {
      final res = await ApiService.post(
        ApiEndpoints.commentLike(commentId),
        {},
      );
      if (res.statusCode != 200) {
        // Revert
        setState(() {
          comment['is_liked'] = isLiked;
          comment['likes_count'] =
              (comment['likes_count'] ?? 0) + (isLiked ? 1 : -1);
        });
        if (mounted) {
          final err = jsonDecode(res.body)['message'] ?? 'Error toggling like';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    } catch (_) {
      // Revert
      setState(() {
        comment['is_liked'] = isLiked;
        comment['likes_count'] =
            (comment['likes_count'] ?? 0) + (isLiked ? 1 : -1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle & Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withAlpha(50)),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comments (${_comments.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton<String>(
                          value: _sort,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: 'top',
                              child: Text('Top Comments'),
                            ),
                            DropdownMenuItem(
                              value: 'new',
                              child: Text('Newest'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _sort = val);
                              _fetchComments();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Comment List — uses scrollController from DraggableScrollableSheet
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada komentar.\nJadi yang pertama berkomentar!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 32),
                        itemBuilder: (context, i) {
                          final c = _comments[i];
                          final user = c['user'] ?? {};
                          final role = user['role'] ?? 'reader';
                          final avatarField = role == 'author'
                              ? 'author_avatar_url'
                              : 'avatar_url';
                          final nameField = role == 'author'
                              ? 'pen_name'
                              : 'name';

                          final rawAvatarUrl = user[avatarField];
                          final avatarUrl = rawAvatarUrl != null
                              ? ApiService.getImageUrl(rawAvatarUrl)
                              : null;
                          final displayName = user[nameField] ?? 'User';
                          final isLiked = c['is_liked'] == true;
                          final pinnedBadges = (user['badges'] as List?) ?? [];

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final uid = user['id'];
                                  if (uid == null) return;
                                  final role = user['role'] ?? 'reader';
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => role == 'author'
                                          ? AuthorProfileScreen(authorId: uid)
                                          : ReaderProfileScreen(userId: uid),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundImage: avatarUrl != null
                                      ? CachedNetworkImageProvider(avatarUrl)
                                      : null,
                                  child: avatarUrl == null
                                      ? const Icon(Icons.person, size: 20)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          role == 'author'
                                              ? Icons.edit_document
                                              : Icons.person,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (pinnedBadges.isNotEmpty)
                                          const SizedBox(width: 6),
                                        ...pinnedBadges.take(2).map((b) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4.0,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: ApiService.getImageUrl(
                                                b['icon_url'],
                                              ),
                                              width: 16,
                                              height: 16,
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const SizedBox(),
                                            ),
                                          );
                                        }),
                                        const SizedBox(width: 8),
                                        Text(
                                          c['created_at_human'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c['body'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => _toggleLike(i),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isLiked
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                size: 16,
                                                color: isLiked
                                                    ? Colors.red
                                                    : Colors.grey[500],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${c['likes_count'] ?? 0}',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        GestureDetector(
                                          onTap: () {},
                                          child: Text(
                                            'Reply',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // Input Area
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 8,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A3E) : Colors.grey[100],
                  border: Border(
                    top: BorderSide(color: Colors.grey.withAlpha(50)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Tulis komentar...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1A1A2E)
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _postComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSubmitting
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: Icon(Icons.send, color: theme.primaryColor),
                            onPressed: _postComment,
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
