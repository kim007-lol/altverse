import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'author_notification_screen.dart';
import 'episode_management_screen.dart';

class AuthorDashboardScreen extends StatefulWidget {
  const AuthorDashboardScreen({super.key});

  @override
  State<AuthorDashboardScreen> createState() => AuthorDashboardScreenState();
}

class AuthorDashboardScreenState extends State<AuthorDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _stats;
  List<dynamic> _allSeries = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  // ─── Data Fetching ───
  Future<void> fetchDashboardData() async {
    try {
      final results = await Future.wait([
        ApiService.get(ApiEndpoints.authorDashboard),
        ApiService.get(ApiEndpoints.authorSeries),
      ]);

      final dashResponse = results[0];
      final seriesResponse = results[1];

      if (dashResponse.statusCode == 200) {
        final data = jsonDecode(dashResponse.body);
        final stats = data['stats'] ?? {};

        List<dynamic> allSeries = [];
        if (seriesResponse.statusCode == 200) {
          allSeries = jsonDecode(seriesResponse.body) ?? [];
        }

        int totalEpisodes = 0;
        for (var s in allSeries) {
          totalEpisodes += (s['episodes_count'] ?? 0) as int;
        }

        setState(() {
          _stats = {
            'total_views': stats['total_views'] ?? 0,
            'followers': stats['followers'] ?? stats['total_followers'] ?? 0,
            'total_series': stats['total_series'] ?? allSeries.length,
            'total_episodes': totalEpisodes,
          };
          _allSeries = allSeries;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Gagal memuat data dari server (${dashResponse.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
        _isLoading = false;
      });
    }
  }

  // ─── Helper ───
  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  List<dynamic> get _drafts =>
      _allSeries.where((s) => s['status'] == 'draft').toList();

  List<dynamic> get _scheduled =>
      _allSeries.where((s) => s['status'] == 'scheduled').toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    fetchDashboardData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchDashboardData,
          color: theme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Greeting + Notification ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, Author 👋',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Continue building your story today.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthorNotificationScreen(),
                          ),
                        );
                      },
                      icon: Badge(
                        smallSize: 8,
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Quick Stats Cards ───
                Row(
                  children: [
                    _StatCard(
                      title: 'Total Views',
                      value: _formatNumber(_stats!['total_views']),
                      icon: Icons.visibility_outlined,
                      color: Colors.blue,
                      theme: theme,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Followers',
                      value: _formatNumber(_stats!['followers']),
                      icon: Icons.people_outline,
                      color: Colors.purple,
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(
                      title: 'Total Series',
                      value: _stats!['total_series'].toString(),
                      icon: Icons.auto_stories_outlined,
                      color: Colors.orange,
                      theme: theme,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Episodes',
                      value: _stats!['total_episodes'].toString(),
                      icon: Icons.layers_outlined,
                      color: Colors.teal,
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ─── Draft Reminder Section ───
                if (_drafts.isNotEmpty) ...[
                  _sectionHeader(
                    'Drafts (${_drafts.length})',
                    Icons.edit_note_rounded,
                    Colors.blueGrey,
                  ),
                  const SizedBox(height: 10),
                  ..._drafts
                      .take(3)
                      .map(
                        (s) => _QuickSeriesCard(
                          title: s['title'] ?? 'No Title',
                          subtitle:
                              '${s['episodes_count'] ?? 0} episodes • Draft',
                          coverUrl: s['cover_url'],
                          statusColor: Colors.blueGrey,
                          theme: theme,
                          onTap: () => _openSeriesDetail(s),
                        ),
                      ),
                  const SizedBox(height: 20),
                ],

                // ─── Scheduled Section ───
                if (_scheduled.isNotEmpty) ...[
                  _sectionHeader(
                    'Scheduled (${_scheduled.length})',
                    Icons.schedule_rounded,
                    Colors.orange,
                  ),
                  const SizedBox(height: 10),
                  ..._scheduled
                      .take(2)
                      .map(
                        (s) => _QuickSeriesCard(
                          title: s['title'] ?? 'No Title',
                          subtitle:
                              '${s['episodes_count'] ?? 0} episodes • Scheduled',
                          coverUrl: s['cover_url'],
                          statusColor: Colors.orange,
                          theme: theme,
                          onTap: () => _openSeriesDetail(s),
                        ),
                      ),
                  const SizedBox(height: 20),
                ],

                // ─── Performance Snapshot ───
                _sectionHeader(
                  'Performance',
                  Icons.trending_up_rounded,
                  Colors.green,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withAlpha(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Total ${_allSeries.length} series • ${_stats!['total_episodes']} episodes',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_formatNumber(_stats!['total_views'])} views total',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_allSeries.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text(
                          'Top Series',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._topSeries().map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s['title'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${_formatNumber(s['total_views'] ?? 0)} views',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> _topSeries() {
    final sorted = List<dynamic>.from(_allSeries);
    sorted.sort(
      (a, b) => ((b['total_views'] ?? 0) as int).compareTo(
        (a['total_views'] ?? 0) as int,
      ),
    );
    return sorted.take(3).toList();
  }

  void _openSeriesDetail(dynamic series) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EpisodeManagementScreen(
          seriesId: series['id'],
          seriesTitle: series['title'],
        ),
      ),
    );
    fetchDashboardData();
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

// ─── Stat Card (reused) ───
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Series Card (for Draft/Scheduled reminders) ───
class _QuickSeriesCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? coverUrl;
  final Color statusColor;
  final ThemeData theme;
  final VoidCallback onTap;

  const _QuickSeriesCard({
    required this.title,
    required this.subtitle,
    this.coverUrl,
    required this.statusColor,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedCoverUrl = ApiService.getImageUrl(coverUrl);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withAlpha(30)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: resolvedCoverUrl.isNotEmpty
                  ? Image.network(
                      resolvedCoverUrl,
                      height: 48,
                      width: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _miniPlaceholder(),
                    )
                  : _miniPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      height: 48,
      width: 36,
      decoration: BoxDecoration(
        color: theme.primaryColor.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.auto_stories,
        size: 16,
        color: theme.primaryColor.withAlpha(100),
      ),
    );
  }
}
