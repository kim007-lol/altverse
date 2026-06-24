import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

class GamificationDashboardScreen extends StatefulWidget {
  const GamificationDashboardScreen({super.key});

  @override
  State<GamificationDashboardScreen> createState() => _GamificationDashboardScreenState();
}

class _GamificationDashboardScreenState extends State<GamificationDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchDailyStatus();
  }

  Future<void> _fetchDailyStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get(ApiEndpoints.gamificationDailyStatus);
      if (response.success && mounted) {
        setState(() {
          _data = response.data;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _error = response.message.isNotEmpty ? response.message : 'Gagal memuat status gamifikasi';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('XP & Gamification', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _fetchDailyStatus,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLevelCard(theme),
                        const SizedBox(height: 24),
                        _buildSectionTitle(theme, 'Daily XP Caps', Icons.track_changes_rounded),
                        const SizedBox(height: 12),
                        _buildDailyCapsList(theme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDailyStatus,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(ThemeData theme) {
    final level = _data?['level'] ?? 0;
    final totalXp = _data?['total_xp'] ?? 0;
    final xpInLevel = _data?['xp_in_level'] ?? 0;
    final xpNeeded = _data?['xp_needed'] ?? 1;
    final progress = (xpInLevel / xpNeeded).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withAlpha(80),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reader Level',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Level $level',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '$totalXp XP',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to Level ${level + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                '$xpInLevel / $xpNeeded XP',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black.withAlpha(50),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDailyCapsList(ThemeData theme) {
    final dailyProgress = (_data?['daily_progress'] as List?) ?? [];
    final totalEarned = _data?['total_earned_today'] ?? 0;
    final totalMax = _data?['total_max_today'] ?? 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withAlpha(40)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total XP Hari Ini', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$totalEarned / $totalMax XP',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: totalMax > 0 ? (totalEarned / totalMax).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: Colors.grey.withAlpha(40),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...dailyProgress.map((item) => _buildCapItem(item, theme)),
      ],
    );
  }

  Widget _buildCapItem(dynamic item, ThemeData theme) {
    final label = item['label'] ?? '';
    final icon = item['icon'] ?? '';
    final earned = item['xp_earned'] ?? 0;
    final max = item['max_xp'] ?? 1;
    final actions = item['action_count'] ?? 0;
    final maxActions = item['max_actions'] ?? 1;
    final isMaxed = item['is_maxed'] == true;

    final progress = (earned / max).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMaxed ? Colors.green.withAlpha(100) : Colors.grey.withAlpha(40),
          width: isMaxed ? 1.5 : 1.0,
        ),
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
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (isMaxed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'MAX',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$actions / $maxActions actions',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                '$earned / $max XP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isMaxed ? Colors.green : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withAlpha(30),
              color: isMaxed ? Colors.green : theme.primaryColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
