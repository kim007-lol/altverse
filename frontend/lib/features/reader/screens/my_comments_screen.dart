import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/api_endpoints.dart';

class MyCommentsScreen extends StatefulWidget {
  const MyCommentsScreen({super.key});

  @override
  State<MyCommentsScreen> createState() => _MyCommentsScreenState();
}

class _MyCommentsScreenState extends State<MyCommentsScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _comments = [];
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments({bool loadMore = false}) async {
    if (loadMore) {
      if (_currentPage >= _lastPage) return;
      _currentPage++;
    } else {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _currentPage = 1;
      });
    }

    try {
      final res = await ApiService.get(
        '${ApiEndpoints.myComments}?page=$_currentPage',
      );

      if (res.statusCode == 200) {
        final bodyData = jsonDecode(res.body);
        final dataList = bodyData['data'] as List;
        setState(() {
          if (loadMore) {
            _comments.addAll(dataList);
          } else {
            _comments = dataList;
          }
          _lastPage = bodyData['last_page'] ?? 1;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      setState(() {
        if (!loadMore) _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteComment(int id, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Komentar?'),
        content: const Text('Tidakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.delete(ApiEndpoints.deleteComment(id));
      if (!mounted) return;
      setState(() {
        _comments.removeAt(index);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Komentar dihapus')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menghapus komentar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Komentar Saya'), centerTitle: true),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Gagal memuat komentar'),
            TextButton(
              onPressed: () => _fetchComments(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada komentar',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchComments(),
      color: theme.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _comments.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _comments.length) {
            if (_currentPage < _lastPage) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () => _fetchComments(loadMore: true),
                    child: const Text('Muat Lebih Banyak'),
                  ),
                ),
              );
            }
            return const SizedBox(height: 40);
          }

          final comment = _comments[index];
          final episode = comment['episode'];
          final seriesStr = episode != null
              ? '${episode['series']['title']} - Ep. ${episode['episode_number']}'
              : 'Unknown Episode';

          final dt = DateTime.parse(comment['created_at']);
          final timeStr =
              '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withAlpha(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        seriesStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  comment['body'] ?? '',
                  style: const TextStyle(height: 1.4, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.thumb_up_alt_rounded,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${comment['likes_count'] ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _deleteComment(comment['id'], index),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
