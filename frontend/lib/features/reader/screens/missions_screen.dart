import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../gamification/providers/mission_provider.dart';
import '../../gamification/models/mission.dart';
import '../../../core/services/auth_provider.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MissionProvider>().fetchMissions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: Consumer<MissionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.missions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.missions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchMissions(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMissionList(provider.dailyMissions, provider),
              _buildMissionList(provider.weeklyMissions, provider),
              _buildMissionList(provider.onceMissions, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMissionList(List<Mission> missions, MissionProvider provider) {
    if (missions.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.fetchMissions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Center(child: Text('No missions available')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchMissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: missions.length,
        itemBuilder: (context, index) {
          final mission = missions[index];
          return _buildMissionCard(mission, provider);
        },
      ),
    );
  }

  Widget _buildMissionCard(Mission mission, MissionProvider provider) {
    final theme = Theme.of(context);
    final double progressPercent = mission.targetCount > 0 
        ? (mission.progress / mission.targetCount).clamp(0.0, 1.0) 
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (mission.xpReward > 0) ...[
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${mission.xpReward} XP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                      if (mission.xpReward > 0 && mission.coinReward > 0)
                        const SizedBox(width: 8),
                      if (mission.coinReward > 0) ...[
                        const Icon(Icons.monetization_on, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('${mission.coinReward} Coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '${mission.progress} / ${mission.targetCount}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: Colors.grey[200],
                        color: mission.isCompleted ? Colors.green : theme.primaryColor,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildActionWidget(mission, provider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionWidget(Mission mission, MissionProvider provider) {
    if (mission.isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Claimed',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (mission.canClaim) {
      return ElevatedButton(
        onPressed: () async {
          final success = await provider.claimMission(mission.id);
          if (!mounted) return;
          if (success) {
            context.read<AuthProvider>().refreshProfile();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reward claimed!')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text('Claim'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'In Progress',
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
    );
  }
}
