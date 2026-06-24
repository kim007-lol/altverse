import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'series_detail_screen.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  List<dynamic> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  Future<void> _fetchCollections() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get(ApiEndpoints.collections);
      if (res.success && mounted) {
        setState(() => _collections = res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _createCollection() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Koleksi Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Koleksi', hintText: 'Cth: Favorit Romantis')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buat')),
        ],
      ),
    );

    if (result != true || nameCtrl.text.trim().isEmpty) return;

    try {
      final res = await ApiService.post(ApiEndpoints.collections, body: {
        'name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim(),
      });
      if (res.success) {
        _fetchCollections();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koleksi berhasil dibuat!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteCollection(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Koleksi?'),
        content: const Text('Koleksi akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.delete(ApiEndpoints.collectionDetail(id));
      _fetchCollections();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Koleksi Saya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
              TextButton.icon(
                onPressed: _createCollection,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat Baru', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _collections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Belum ada koleksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Buat koleksi untuk mengorganisir series favoritmu!', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _createCollection, icon: const Icon(Icons.add), label: const Text('Buat Koleksi')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchCollections,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: _collections.length,
                    itemBuilder: (ctx, i) {
                      final col = _collections[i];
                      final seriesCount = (col['series'] as List?)?.length ?? col['series_count'] ?? 0;
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CollectionDetailScreen(collectionId: col['id'], collectionName: col['name'] ?? 'Koleksi')),
                          );
                          _fetchCollections();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withAlpha(40)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(color: theme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.collections_bookmark, color: theme.primaryColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(col['name'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text('$seriesCount series', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
                                onPressed: () => _deleteCollection(col['id']),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// Collection Detail Screen
// ═══════════════════════════════════════════
class CollectionDetailScreen extends StatefulWidget {
  final int collectionId;
  final String collectionName;

  const CollectionDetailScreen({super.key, required this.collectionId, required this.collectionName});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  Map<String, dynamic>? _collection;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get(ApiEndpoints.collectionDetail(widget.collectionId));
      if (res.success && mounted) {
        setState(() => _collection = res.data['data'] ?? res.data);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _removeSeries(int seriesId) async {
    try {
      await ApiService.delete(ApiEndpoints.collectionRemoveSeries(widget.collectionId, seriesId));
      _fetchDetail();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Series dihapus dari koleksi')));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.collectionName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collection == null
              ? const Center(child: Text('Koleksi tidak ditemukan'))
              : _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final series = (_collection!['series'] as List?) ?? [];

    if (series.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Koleksi masih kosong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Tambahkan series dari halaman detail series', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: series.length,
        itemBuilder: (ctx, i) {
          final s = series[i];
          final coverUrl = s['cover_url'] != null ? ApiService.getImageUrl(s['cover_url']) : null;

          return GestureDetector(
            onTap: () {
              if (s['id'] != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesDetailScreen(seriesId: s['id'])));
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.withAlpha(25), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 60, height: 80,
                      child: coverUrl != null
                          ? Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _placeholder())
                          : _placeholder(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(s['author']?['pen_name'] ?? 'Unknown', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                    onPressed: () => _removeSeries(s['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 60, height: 80,
    color: Colors.grey[200],
    child: Icon(Icons.auto_stories, color: Colors.grey[400]),
  );
}
