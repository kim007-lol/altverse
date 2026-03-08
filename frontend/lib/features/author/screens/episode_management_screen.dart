import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'page_editor_screen.dart';

class EpisodeManagementScreen extends StatefulWidget {
  final int seriesId;
  final String seriesTitle;

  const EpisodeManagementScreen({
    super.key,
    required this.seriesId,
    required this.seriesTitle,
  });

  @override
  State<EpisodeManagementScreen> createState() =>
      _EpisodeManagementScreenState();
}

class _EpisodeManagementScreenState extends State<EpisodeManagementScreen> {
  final List<_EpisodeDraft> _episodes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEpisodes();
  }

  Future<void> _fetchEpisodes() async {
    try {
      final response = await ApiService.get(
        ApiEndpoints.authorEpisodes(widget.seriesId),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _episodes.clear();
          for (var item in data) {
            _episodes.add(
              _EpisodeDraft(
                id: item['id'],
                title: item['title'] ?? 'Untitled',
                episodeNumber: item['episode_number'] ?? 1,
                status: item['status'] ?? 'draft',
                pagesCount: item['pages_count'] ?? 0,
                coverUrl: item['cover_url'],
                publishedAt: item['published_at'],
              ),
            );
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Gagal mengambil data episode (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal terhubung ke server. Periksa koneksi Anda.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manajemen Episode',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            Text(
              widget.seriesTitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: () => _addEpisode(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _fetchEpisodes();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : _episodes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Belum ada episode'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _addEpisode(),
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Episode Pertama'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchEpisodes,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _episodes.length,
                itemBuilder: (context, i) {
                  final episode = _episodes[i];
                  return _EpisodeTile(
                    episode: episode,
                    theme: theme,
                    onTap: () => _openPreview(episode),
                    onEdit: () => _openPageEditor(episode),
                    onPublish:
                        episode.status == 'draft' && episode.pagesCount > 0
                        ? () => _publishEpisode(episode)
                        : null,
                    onDelete: () => _deleteEpisode(episode, i),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _addEpisode() async {
    final titleCtrl = TextEditingController();
    final theme = Theme.of(context);

    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Episode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Episode 1: The Beginning',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx, titleCtrl.text.trim());
                },
                child: const Text(
                  'Add Episode',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (title == null || title.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post(
        ApiEndpoints.authorEpisodes(widget.seriesId),
        {'title': title},
      );
      if (response.statusCode == 201) {
        await _fetchEpisodes();
        // Open page editor for this new episode
        final newEp = _episodes.lastOrNull;
        if (newEp != null && mounted) {
          _openPageEditor(newEp);
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuat episode: ${response.body}')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openPreview(_EpisodeDraft episode) async {
    if (episode.id == null || episode.pagesCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada halaman untuk di-preview')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(
        ApiEndpoints.authorPages(episode.id!),
      );
      if (mounted) setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final pages = data
            .map((p) => ApiService.getImageUrl(p['image_path']))
            .toList();
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PreviewScreen(title: episode.title, pages: pages),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat halaman preview')),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openPageEditor(_EpisodeDraft episode) async {
    if (episode.id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PageEditorScreen(
          episodeId: episode.id!,
          episodeTitle: episode.title,
        ),
      ),
    );
    // Refresh after returning
    _fetchEpisodes();
  }

  Future<void> _publishEpisode(_EpisodeDraft episode) async {
    if (episode.id == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post(
        ApiEndpoints.authorEpisodePublish(episode.id!),
        {},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Episode berhasil dipublish! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _fetchEpisodes();
      } else {
        setState(() => _isLoading = false);
        final body = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body['message'] ?? 'Gagal publish')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEpisode(_EpisodeDraft episode, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Episode?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${episode.title}"? Semua halaman akan ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || episode.id == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.delete(
        ApiEndpoints.authorEpisodeDelete(episode.id!),
      );
      if (response.statusCode == 200) {
        _fetchEpisodes();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus episode')),
          );
        }
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }
}

// ─── Data Model ───
class _EpisodeDraft {
  int? id;
  String title;
  int episodeNumber;
  String status;
  int pagesCount;
  String? coverUrl;
  String? publishedAt;

  _EpisodeDraft({
    this.id,
    required this.title,
    this.episodeNumber = 1,
    this.status = 'draft',
    this.pagesCount = 0,
    this.coverUrl,
    this.publishedAt,
  });
}

// ─── Episode Tile Widget ───
class _EpisodeTile extends StatelessWidget {
  final _EpisodeDraft episode;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onPublish;
  final VoidCallback onDelete;

  const _EpisodeTile({
    required this.episode,
    required this.theme,
    required this.onTap,
    required this.onEdit,
    required this.onPublish,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (episode.status) {
      case 'published':
        statusColor = Colors.green;
        statusText = 'Published';
        break;
      case 'scheduled':
        statusColor = Colors.orange;
        statusText = 'Scheduled';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Draft';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: episode.status == 'published'
              ? Border.all(color: Colors.green.withAlpha(30))
              : null,
        ),
        child: Row(
          children: [
            // Episode Number Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Ep${episode.episodeNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${episode.pagesCount} halaman',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Edit button
            IconButton(
              icon: Icon(Icons.edit_note, size: 20, color: theme.primaryColor),
              onPressed: onEdit,
              tooltip: 'Edit Pages',
            ),
            // Publish button (only for drafts with pages)
            if (onPublish != null)
              IconButton(
                icon: Icon(
                  Icons.publish_rounded,
                  size: 20,
                  color: Colors.green[600],
                ),
                onPressed: onPublish,
                tooltip: 'Publish',
              ),
            // Delete button
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red[400],
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
