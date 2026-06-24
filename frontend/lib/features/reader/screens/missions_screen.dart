import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _dailyMissions = [];
  List<dynamic> _weeklyMissions = [];
  List<dynamic> _onceMissions = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchMissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMissions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      debugPrint('=== MISSIONS DEBUG START ===');
      debugPrint('Fetching missions from: ${ApiEndpoints.missions}');

      final res = await ApiService.get(ApiEndpoints.missions);

      debugPrint('Response success: ${res.success}');
      debugPrint('Response statusCode: ${res.statusCode}');
      debugPrint('Response message: ${res.message}');
      debugPrint('Response data type: ${res.data.runtimeType}');
      debugPrint('Response data: ${res.data}');

      if (res.success && mounted) {
        debugPrint('Response is successful, parsing missions...');

        List<dynamic> missions = [];

        if (res.data is List) {
          missions = res.data as List;
          debugPrint('Response is a direct list with ${missions.length} missions');
        } else if (res.data is Map && res.data.containsKey('missions')) {
          missions = res.data['missions'] as List;
          debugPrint('Found ${missions.length} missions in data.missions');
        } else {
          debugPrint('ERROR: Unexpected response structure');
          debugPrint('Available keys: ${res.data is Map ? res.data.keys.toList() : "N/A"}');
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
          return;
        }

        final daily = missions.where((m) => m['type'] == 'daily').toList();
        final weekly = missions.where((m) => m['type'] == 'weekly').toList();
        final once = missions.where((m) => m['type'] == 'once').toList();

        debugPrint('Daily missions: ${daily.length}');
        debugPrint('Weekly missions: ${weekly.length}');
        debugPrint('Once missions: ${once.length}');

        setState(() {
          _dailyMissions = daily;
          _weeklyMissions = weekly;
          _onceMissions = once;
          _isLoading = false;
        });

        debugPrint('State updated successfully');
      } else {
        debugPrint('Response failed or widget unmounted');
        debugPrint('Error message: ${res.message}');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }

      debugPrint('=== MISSIONS DEBUG END ===');
    } catch (e, stackTrace) {
      debugPrint('=== MISSIONS ERROR ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _claimReward(int missionId) async {
    try {
      final res = await ApiService.post(ApiEndpoints.claimMission(missionId.toString()), body: {});

      if (res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message'] ?? 'Reward claimed!'), backgroundColor: Colors.green),
        );
        _fetchMissions(); // Refresh missions
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message.isNotEmpty ? res.message : 'Failed to claim reward'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to claim reward'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Missions'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Missions'), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 24),
                const Text(
                  'Failed to Load Missions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check:\n• You are logged in as Reader\n• Backend server is running\n• Internet connection is stable',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchMissions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      appBar: AppBar(
        title: const Text('Missions'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: _showHowItWorks, tooltip: 'How it works'),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMissions,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMissionList(_dailyMissions, 'daily'),
            _buildMissionList(_weeklyMissions, 'weekly'),
            _buildMissionList(_onceMissions, 'once'),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionList(List<dynamic> missions, String type) {
    if (missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No missions available', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: missions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final mission = missions[index];
        return _buildMissionCard(mission, type);
      },
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission, String type) {
    final theme = Theme.of(context);
    final name = mission['name'] ?? '';
    final description = mission['description'] ?? '';
    final xpReward = mission['xp_reward'] ?? 0;
    final coinReward = mission['coin_reward'] ?? 0;
    final progress = mission['progress'] ?? 0;
    final targetCount = mission['target_count'] ?? 1;
    final isCompleted = mission['is_completed'] == true;
    final isClaimed = mission['is_claimed'] == true;
    final canClaim = mission['can_claim'] == true;

    final progressPercent = targetCount > 0 ? (progress / targetCount).clamp(0.0, 1.0) : 0.0;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isClaimed) {
      statusColor = Colors.grey;
      statusText = 'Claimed';
      statusIcon = Icons.check_circle;
    } else if (canClaim) {
      statusColor = Colors.green;
      statusText = 'Claim';
      statusIcon = Icons.card_giftcard;
    } else if (isCompleted) {
      statusColor = theme.primaryColor;
      statusText = 'Complete';
      statusIcon = Icons.check_circle_outline;
    } else {
      statusColor = Colors.grey;
      statusText = 'In Progress';
      statusIcon = Icons.hourglass_empty;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canClaim ? Colors.green.withAlpha(100) : Colors.grey.withAlpha(50),
          width: canClaim ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: theme.primaryColor.withAlpha(25), shape: BoxShape.circle),
                  child: Icon(_getMissionIcon(type), color: theme.primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            if (!isClaimed) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 8,
                        backgroundColor: Colors.grey.withAlpha(25),
                        valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : theme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$progress/$targetCount',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Rewards and status
            Row(
              children: [
                if (xpReward > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '+$xpReward XP',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (coinReward > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '+$coinReward Coins',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                if (canClaim)
                  ElevatedButton.icon(
                    onPressed: () => _claimReward(mission['id']),
                    icon: Icon(statusIcon, size: 18),
                    label: Text(statusText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMissionIcon(String type) {
    switch (type) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.calendar_month;
      case 'once':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }

  void _showHowItWorks() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  const Text('How Missions Work', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              _buildInfoRow(
                Icons.today,
                'Daily Missions',
                'Reset every day at midnight. Complete them daily for consistent rewards!',
              ),
              const SizedBox(height: 12),

              _buildInfoRow(
                Icons.calendar_month,
                'Weekly Missions',
                'Reset every Monday. Bigger challenges with better rewards!',
              ),
              const SizedBox(height: 12),

              _buildInfoRow(
                Icons.emoji_events,
                'Achievements',
                'One-time missions. Complete them once and claim permanent rewards!',
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete missions to earn XP and Coins. Don\'t forget to claim your rewards!',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got it!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}
