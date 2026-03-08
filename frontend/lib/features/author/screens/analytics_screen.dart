import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String _selectedRange = '7d';
  final List<String> _ranges = ['7d', '30d', '90d'];

  // Data
  Map<String, dynamic> _overview = {};
  List<int> _trendViews = [];
  List<dynamic> _topSeries = [];
  List<dynamic> _topEpisodes = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.get(
          '${ApiEndpoints.authorAnalyticsOverview}?range=$_selectedRange',
        ),
        ApiService.get(
          '${ApiEndpoints.authorAnalyticsTrend}?range=$_selectedRange',
        ),
        ApiService.get(ApiEndpoints.authorAnalyticsTopSeries),
        ApiService.get(ApiEndpoints.authorAnalyticsTopEpisodes),
      ]);

      final overviewResp = results[0];
      final trendResp = results[1];
      final topSeriesResp = results[2];
      final topEpisodesResp = results[3];

      setState(() {
        if (overviewResp.statusCode == 200) {
          _overview = jsonDecode(overviewResp.body) ?? {};
        }
        if (trendResp.statusCode == 200) {
          final trendData = jsonDecode(trendResp.body) ?? {};
          _trendViews = List<int>.from(
            (trendData['views'] ?? []).map((v) => (v as num).toInt()),
          );
        }
        if (topSeriesResp.statusCode == 200) {
          _topSeries = jsonDecode(topSeriesResp.body) ?? [];
        }
        if (topEpisodesResp.statusCode == 200) {
          _topEpisodes = jsonDecode(topEpisodesResp.body) ?? [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onRangeChanged(String range) {
    setState(() => _selectedRange = range);
    _fetchAll();
  }

  String _formatNumber(num n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAll,
          color: theme.primaryColor,
          child: _isLoading ? _buildSkeleton(theme) : _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header + Range Filter ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Track your performance',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
              _buildRangeFilter(theme),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Section 1: Key Metrics ───
          Row(
            children: [
              _MetricCard(
                label: 'Views',
                value: _formatNumber(_overview['total_views'] ?? 0),
                icon: Icons.visibility_outlined,
                color: Colors.blue,
                theme: theme,
              ),
              const SizedBox(width: 12),
              _MetricCard(
                label: 'Followers',
                value: _formatNumber(_overview['followers'] ?? 0),
                icon: Icons.people_outline,
                color: Colors.purple,
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricCard(
                label: 'Likes',
                value: _formatNumber(_overview['total_likes'] ?? 0),
                icon: Icons.favorite_outline,
                color: Colors.red,
                theme: theme,
              ),
              const SizedBox(width: 12),
              _MetricCard(
                label: 'Engagement',
                value: '${_overview['engagement_rate'] ?? 0}%',
                icon: Icons.trending_up_rounded,
                color: Colors.green,
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Section 2: Trend Chart ───
          _SectionCard(
            theme: theme,
            title: 'Performance Trend',
            subtitle: 'Views per day',
            child: SizedBox(
              height: 160,
              child: _trendViews.isEmpty
                  ? Center(
                      child: Text(
                        'No data yet',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    )
                  : CustomPaint(
                      size: Size.infinite,
                      painter: _TrendChartPainter(
                        values: _trendViews,
                        color: theme.primaryColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // ─── Section 3: Top Series ───
          _sectionHeader(
            'Top Performing Series',
            Icons.emoji_events_outlined,
            Colors.amber,
          ),
          const SizedBox(height: 10),
          if (_topSeries.isEmpty)
            _emptySection('Belum ada data series')
          else
            ..._topSeries.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              return _TopSeriesCard(
                rank: idx + 1,
                title: s['title'] ?? '',
                views: _formatNumber(s['total_views'] ?? 0),
                episodes: s['episodes_count'] ?? 0,
                coverUrl: s['cover_url'],
                theme: theme,
              );
            }),
          const SizedBox(height: 20),

          // ─── Section 4: Top Episodes ───
          _sectionHeader(
            'Best Episodes',
            Icons.play_circle_outline,
            Colors.teal,
          ),
          const SizedBox(height: 10),
          if (_topEpisodes.isEmpty)
            _emptySection('Belum ada data episode')
          else
            ..._topEpisodes.asMap().entries.map((entry) {
              final idx = entry.key;
              final ep = entry.value;
              return _TopEpisodeCard(
                rank: idx + 1,
                episodeTitle: ep['episode_title'] ?? '',
                seriesTitle: ep['series_title'] ?? '',
                episodeNumber: ep['episode_number'] ?? 0,
                viewCount: _formatNumber(ep['view_count'] ?? 0),
                theme: theme,
              );
            }),
          const SizedBox(height: 20),

          // ─── Author Tier ───
          _buildTierBadge(theme),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRangeFilter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _ranges.map((r) {
          final isActive = r == _selectedRange;
          return GestureDetector(
            onTap: () => _onRangeChanged(r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? theme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.replaceAll('d', ' days'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTierBadge(ThemeData theme) {
    final tier = _overview['author_tier'] ?? 'bronze';
    final tierEmoji = switch (tier) {
      'popular' => '👑',
      'gold' => '🥇',
      'silver' => '🥈',
      _ => '🥉',
    };
    final tierName = tier.toString().isNotEmpty
        ? '${tier[0].toUpperCase()}${tier.substring(1)}'
        : 'Bronze';

    final tierProgress =
        _overview['tier_progress'] as Map<String, dynamic>? ?? {};
    final benefits = List<String>.from(tierProgress['benefits'] ?? []);

    // Determine next tier
    final nextTier = switch (tier) {
      'bronze' => 'silver',
      'silver' => 'gold',
      'gold' => 'popular',
      _ => '',
    };
    final nextTierName = switch (tier) {
      'bronze' => 'Silver',
      'silver' => 'Gold',
      'gold' => 'Popular',
      _ => '',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withAlpha(30),
            theme.primaryColor.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Tier Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Text(tierEmoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Author Tier',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$tierEmoji $tierName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Benefits
          if (benefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: benefits.map((b) {
                final label = switch (b) {
                  'can_customize_banner' => '🎨 Banner',
                  'can_tip' => '💰 Tipping',
                  'is_verified' => '✅ Verified',
                  _ => b,
                };
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Next Tier Progress
          if (nextTier.isNotEmpty && tierProgress.containsKey(nextTier)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(180),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next: $nextTierName',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._buildProgressBars(
                    tierProgress[nextTier] as Map<String, dynamic>? ?? {},
                    theme,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildProgressBars(
    Map<String, dynamic> tierData,
    ThemeData theme,
  ) {
    final required = tierData['required'] as Map<String, dynamic>? ?? {};
    final current = tierData['current'] as Map<String, dynamic>? ?? {};
    final widgets = <Widget>[];

    required.forEach((key, reqValue) {
      final curValue = current[key];
      final label = switch (key) {
        'followers' => '👥 Followers',
        'published_episodes' => '📖 Published Episodes',
        'total_views' => '👁 Total Views',
        'has_archived_series' => '📚 Completed Series',
        _ => key,
      };

      if (reqValue is bool) {
        // Boolean requirement (archived series)
        final met = curValue == true;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  met ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: met ? Colors.green : Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        );
      } else {
        // Numeric requirement
        final reqNum = (reqValue as num).toDouble();
        final curNum = (curValue as num?)?.toDouble() ?? 0;
        final progress = (curNum / reqNum).clamp(0.0, 1.0);

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      '${_formatNumber(curNum)} / ${_formatNumber(reqNum)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: progress >= 1.0
                            ? Colors.green
                            : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: progress >= 1.0 ? Colors.green : theme.primaryColor,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    return widgets;
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

  Widget _emptySection(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          const SizedBox(height: 4),
          Text(
            'Start publishing to see analytics 📊',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ─── Loading Skeleton ───
  Widget _buildSkeleton(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(160, double.infinity, theme),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _shimmerBox(90, double.infinity, theme)),
              const SizedBox(width: 12),
              Expanded(child: _shimmerBox(90, double.infinity, theme)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _shimmerBox(90, double.infinity, theme)),
              const SizedBox(width: 12),
              Expanded(child: _shimmerBox(90, double.infinity, theme)),
            ],
          ),
          const SizedBox(height: 24),
          _shimmerBox(200, double.infinity, theme),
          const SizedBox(height: 16),
          _shimmerBox(60, double.infinity, theme),
          const SizedBox(height: 8),
          _shimmerBox(60, double.infinity, theme),
          const SizedBox(height: 8),
          _shimmerBox(60, double.infinity, theme),
        ],
      ),
    );
  }

  Widget _shimmerBox(double h, double w, ThemeData theme) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─── Reusable Widgets ───

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _MetricCard({
    required this.label,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final ThemeData theme;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TopSeriesCard extends StatelessWidget {
  final int rank;
  final String title;
  final String views;
  final int episodes;
  final String? coverUrl;
  final ThemeData theme;

  const _TopSeriesCard({
    required this.rank,
    required this.title,
    required this.views,
    required this.episodes,
    this.coverUrl,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiService.getImageUrl(coverUrl);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withAlpha(25)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _rankColor(rank).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _rankColor(rank),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: resolvedUrl.isNotEmpty
                ? Image.network(
                    resolvedUrl,
                    width: 36,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _coverPlaceholder(),
                  )
                : _coverPlaceholder(),
          ),
          const SizedBox(width: 10),
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
                  '$episodes episodes',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                views,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.primaryColor,
                ),
              ),
              Text(
                'views',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    return switch (rank) {
      1 => Colors.amber,
      2 => Colors.blueGrey,
      3 => Colors.brown,
      _ => Colors.grey,
    };
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 36,
      height: 48,
      decoration: BoxDecoration(
        color: theme.primaryColor.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.auto_stories,
        size: 16,
        color: theme.primaryColor.withAlpha(80),
      ),
    );
  }
}

class _TopEpisodeCard extends StatelessWidget {
  final int rank;
  final String episodeTitle;
  final String seriesTitle;
  final int episodeNumber;
  final String viewCount;
  final ThemeData theme;

  const _TopEpisodeCard({
    required this.rank,
    required this.episodeTitle,
    required this.seriesTitle,
    required this.episodeNumber,
    required this.viewCount,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withAlpha(25)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.teal.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ep $episodeNumber — $episodeTitle',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  seriesTitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                viewCount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.teal[700],
                ),
              ),
              Text(
                'views',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Custom Trend Line Chart ───
class _TrendChartPainter extends CustomPainter {
  final List<int> values;
  final Color color;

  _TrendChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce(max).toDouble();
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;

    final points = <Offset>[];
    final w = size.width / (values.length - 1).clamp(1, 999);

    for (var i = 0; i < values.length; i++) {
      final x = w * i;
      final y =
          size.height - (values[i] / effectiveMax * (size.height - 20)) - 10;
      points.add(Offset(x, y));
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withAlpha(30)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        // Smooth curve
        final prev = points[i - 1];
        final curr = points[i];
        final cx = (prev.dx + curr.dx) / 2;
        path.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Fill gradient below line
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(60), color.withAlpha(5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    // Dots
    final dotPaint = Paint()..color = color;
    final whitePaint = Paint()..color = Colors.white;
    for (final p in points) {
      canvas.drawCircle(p, 5, whitePaint);
      canvas.drawCircle(p, 3.5, dotPaint);
    }

    // Value labels on top
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < points.length; i++) {
      if (values.length <= 10 || i % (values.length ~/ 7) == 0) {
        textPainter.text = TextSpan(
          text: _shortNum(values[i]),
          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(points[i].dx - textPainter.width / 2, points[i].dy - 16),
        );
      }
    }
  }

  String _shortNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter old) => old.values != values;
}
