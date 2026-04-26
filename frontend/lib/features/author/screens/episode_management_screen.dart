import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'page_editor_screen.dart';

class EpisodeManagementScreen extends StatefulWidget {
  final int seriesId;
  final String seriesTitle;

  const EpisodeManagementScreen({super.key, required this.seriesId, required this.seriesTitle});

  @override
  State<EpisodeManagementScreen> createState() => _EpisodeManagementScreenState();
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

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchEpisodes() async {
    try {
      final response = await ApiService.get(ApiEndpoints.authorEpisodes(widget.seriesId));
      if (response.success) {
        final List<dynamic> data = response.data;
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
                isPremium: item['is_premium'] ?? false,
                coinPrice: item['coin_price'] ?? 0,
              ),
            );
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal mengambil data episode (${response.statusCode})';
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
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manajemen Episode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.textTheme.titleLarge?.color),
            ),
            Text(
              widget.seriesTitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.add_box_rounded), onPressed: () => _addEpisode())],
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
                    style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
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
                    onSettings: () => _openSettings(episode),
                    onPublish: episode.status == 'draft' && episode.pagesCount > 0
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Episode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Episode 1: The Beginning',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx, titleCtrl.text.trim());
                },
                child: const Text('Add Episode', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );

    if (title == null || title.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post(ApiEndpoints.authorEpisodes(widget.seriesId), body: {'title': title});
      if (response.success) {
        await _fetchEpisodes();
        // Open page editor for this new episode
        final newEp = _episodes.lastOrNull;
        if (newEp != null && mounted) {
          _openPageEditor(newEp);
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal membuat episode: ${response.message}')));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openPreview(_EpisodeDraft episode) async {
    if (episode.id == null || episode.pagesCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada halaman untuk di-preview')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(ApiEndpoints.authorPages(episode.id!));
      if (mounted) setState(() => _isLoading = false);

      if (response.success) {
        final List<dynamic> data = response.data;
        final pages = data.map((p) => ApiService.getImageUrl(p['image_path'])).toList();
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PreviewScreen(title: episode.title, pages: pages),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memuat halaman preview')));
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
        builder: (_) => PageEditorScreen(episodeId: episode.id!, episodeTitle: episode.title),
      ),
    );
    // Refresh after returning
    _fetchEpisodes();
  }

  void _openSettings(_EpisodeDraft episode) async {
    if (episode.id == null) return;
    
    bool isPremium = episode.isPremium;
    final priceCtrl = TextEditingController(text: episode.coinPrice > 0 ? episode.coinPrice.toString() : '5');
    final titleCtrl = TextEditingController(text: episode.title);
    
    final theme = Theme.of(context);

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pengaturan Episode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Judul Episode',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isPremium ? Colors.orange.withValues(alpha: 0.1) : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isPremium ? Colors.orange : Colors.transparent),
                ),
                child: SwitchListTile(
                  title: const Text('Episode Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Pembaca harus membeli dengan koin untuk membaca episode ini.'),
                  value: isPremium,
                  activeTrackColor: Colors.orange,
                  onChanged: (val) => setModalState(() => isPremium = val),
                ),
              ),
              if (isPremium) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Harga (Koin)',
                    prefixIcon: const Icon(Icons.monetization_on, color: Colors.amber),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final newTitle = titleCtrl.text.trim();
                    final newPrice = int.tryParse(priceCtrl.text) ?? 5;
                    
                    if (newTitle.isEmpty) return;

                    Navigator.pop(ctx, true);
                    
                    setState(() => _isLoading = true);
                    try {
                      final response = await ApiService.patch(
                        ApiEndpoints.authorEpisodeUpdate(episode.id!),
                        body: {
                          'title': newTitle,
                          'is_premium': isPremium,
                          'coin_price': isPremium ? newPrice : 0,
                        },
                      );
                      
                      if (response.success) {
                        _fetchEpisodes();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pengaturan episode disimpan!'), backgroundColor: Colors.green),
                          );
                        }
                      } else {
                        setState(() => _isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(response.message), backgroundColor: Colors.red),
                          );
                        }
                      }
                    } catch (e) {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('Simpan Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publishEpisode(_EpisodeDraft episode) async {
    if (episode.id == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post(ApiEndpoints.authorEpisodePublish(episode.id!), body: {});
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Episode berhasil dipublish! 🎉'), backgroundColor: Colors.green),
          );
        }
        _fetchEpisodes();
      } else {
        setState(() => _isLoading = false);
        final body = response.data;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body['message'] ?? 'Gagal publish')));
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
        content: Text('Apakah kamu yakin ingin menghapus "${episode.title}"? Semua halaman akan ikut terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
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
      final response = await ApiService.delete(ApiEndpoints.authorEpisodeDelete(episode.id!));
      if (response.success) {
        _fetchEpisodes();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus episode')));
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
  bool isPremium;
  int coinPrice;

  _EpisodeDraft({
    this.id,
    required this.title,
    this.episodeNumber = 1,
    this.status = 'draft',
    this.pagesCount = 0,
    this.coverUrl,
    this.publishedAt,
    this.isPremium = false,
    this.coinPrice = 0,
  });
}

// ─── Episode Tile Widget ───
class _EpisodeTile extends StatelessWidget {
  final _EpisodeDraft episode;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onSettings;
  final VoidCallback? onPublish;
  final VoidCallback onDelete;

  const _EpisodeTile({
    required this.episode,
    required this.theme,
    required this.onTap,
    required this.onEdit,
    required this.onSettings,
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
          border: episode.status == 'published' ? Border.all(color: Colors.green.withAlpha(30)) : null,
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.primaryColor),
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
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text('${episode.pagesCount} halaman', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      if (episode.isPremium)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 12, color: Colors.orange[400]),
                            const SizedBox(width: 2),
                            Text(
                              '${episode.coinPrice} Coins',
                              style: TextStyle(fontSize: 11, color: Colors.orange[600], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: Text(
                statusText,
                style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
            // Edit Pages button
            IconButton(
              icon: Icon(Icons.edit_note, size: 20, color: theme.primaryColor),
              onPressed: onEdit,
              tooltip: 'Edit Pages',
            ),
            // Settings button
            IconButton(
              icon: Icon(Icons.settings_outlined, size: 20, color: Colors.grey[600]),
              onPressed: onSettings,
              tooltip: 'Episode Settings',
            ),
            // Publish button (only for drafts with pages)
            if (onPublish != null)
              IconButton(
                icon: Icon(Icons.publish_rounded, size: 20, color: Colors.green[600]),
                onPressed: onPublish,
                tooltip: 'Publish',
              ),
            // Delete button
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
