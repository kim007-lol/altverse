import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'episode_management_screen.dart';

class SeriesManagementScreen extends StatefulWidget {
  const SeriesManagementScreen({super.key});

  @override
  State<SeriesManagementScreen> createState() => _SeriesManagementScreenState();
}

class _SeriesManagementScreenState extends State<SeriesManagementScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _allSeries = [];
  final _searchCtrl = TextEditingController();

  late TabController _tabController;
  final List<String> _tabLabels = ['Draft', 'Published', 'Archived'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _fetchSeries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSeries() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(ApiEndpoints.authorSeries);
      if (response.statusCode == 200) {
        setState(() {
          _allSeries = jsonDecode(response.body) ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _filteredByTab() {
    final status = _tabLabels[_tabController.index].toLowerCase();
    var list = _allSeries.where((s) => s['status'] == status).toList();

    // Apply search filter
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where(
            (s) =>
                (s['title'] ?? '').toString().toLowerCase().contains(query) ||
                (s['genre'] ?? '').toString().toLowerCase().contains(query),
          )
          .toList();
    }

    return list;
  }

  Future<void> _changeSeriesStatus(int id, String newStatus) async {
    try {
      final response = await ApiService.put(
        '${ApiEndpoints.authorSeries}/$id',
        {'status': newStatus},
      );
      if (response.statusCode == 200) {
        _fetchSeries();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengubah status series')),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _deleteSeries(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Series?'),
        content: const Text(
          'Series dan semua episode di dalamnya akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.delete(
          '${ApiEndpoints.authorSeries}/$id',
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          _fetchSeries();
        }
      } catch (_) {}
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header + Search ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'My Series',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Search Bar ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari series...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // ─── Tab Bar ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() {}),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  dividerColor: Colors.transparent,
                  tabs: _tabLabels.map((label) {
                    final count = _allSeries
                        .where((s) => s['status'] == label.toLowerCase())
                        .length;
                    return Tab(child: Text('$label ($count)'));
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ─── Series List ───
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchSeries,
                      child: _filteredByTab().isEmpty
                          ? _buildEmptyState(theme)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              itemCount: _filteredByTab().length,
                              itemBuilder: (ctx, i) {
                                final series = _filteredByTab()[i];
                                return _SeriesWorkCard(
                                  id: series['id'],
                                  title: series['title'] ?? 'No Title',
                                  coverUrl: series['cover_url'],
                                  genre: series['genre'] ?? '',
                                  episodes: (series['episodes_count'] ?? 0)
                                      .toString(),
                                  views: _formatNumber(
                                    series['total_views'] ?? 0,
                                  ),
                                  status: (series['status'] ?? 'draft')
                                      .toString(),
                                  theme: theme,
                                  onStatusChange: (newStatus) =>
                                      _changeSeriesStatus(
                                        series['id'],
                                        newStatus,
                                      ),
                                  onDelete: () => _deleteSeries(series['id']),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EpisodeManagementScreen(
                                          seriesId: series['id'],
                                          seriesTitle: series['title'],
                                        ),
                                      ),
                                    );
                                    _fetchSeries();
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada series di tab ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gunakan tombol + untuk membuat series baru',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Series Workspace Card (Full CRUD) ───
class _SeriesWorkCard extends StatelessWidget {
  final int id;
  final String title;
  final String? coverUrl;
  final String genre;
  final String episodes;
  final String views;
  final String status;
  final ThemeData theme;
  final Function(String) onStatusChange;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SeriesWorkCard({
    required this.id,
    required this.title,
    this.coverUrl,
    required this.genre,
    required this.episodes,
    required this.views,
    required this.status,
    required this.theme,
    required this.onStatusChange,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      'published' => Colors.green,
      'scheduled' => Colors.orange,
      'archived' => Colors.red,
      _ => Colors.blueGrey, // draft
    };
    final displayStatus = status.isNotEmpty
        ? '${status[0].toUpperCase()}${status.substring(1)}'
        : 'Draft';

    final resolvedCoverUrl = ApiService.getImageUrl(coverUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha(30)),
        ),
        child: Row(
          children: [
            // Cover image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: resolvedCoverUrl.isNotEmpty
                  ? Image.network(
                      resolvedCoverUrl,
                      height: 80,
                      width: 56,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 56,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, e, st) => _coverPlaceholder(),
                    )
                  : _coverPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (genre.isNotEmpty)
                    Text(
                      genre,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 13,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$episodes ep',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.visibility_outlined,
                        size: 13,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$views views',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── 3-dot Menu ───
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    onTap();
                    break;
                  case 'draft':
                  case 'published':
                  case 'archived':
                    onStatusChange(action);
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Series'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                if (status != 'published')
                  const PopupMenuItem(
                    value: 'published',
                    child: Row(
                      children: [
                        Icon(Icons.publish_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Publish'),
                      ],
                    ),
                  ),
                if (status != 'draft')
                  const PopupMenuItem(
                    value: 'draft',
                    child: Row(
                      children: [
                        Icon(Icons.drafts_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Move to Draft'),
                      ],
                    ),
                  ),
                if (status != 'archived')
                  const PopupMenuItem(
                    value: 'archived',
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Archive'),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      displayStatus,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.more_vert, size: 14, color: statusColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      height: 80,
      width: 56,
      decoration: BoxDecoration(
        color: theme.primaryColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.auto_stories,
        size: 24,
        color: theme.primaryColor.withAlpha(100),
      ),
    );
  }
}
