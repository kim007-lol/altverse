import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _missions = [];
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _fetchMissions();
  }

  Future<void> _fetchMissions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final res = await ApiService.get(ApiEndpoints.missions);
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        setState(() {
          _missions = body['missions'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _claimMission(String code) async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      final res = await ApiService.post(ApiEndpoints.claimMission(code), {});

      if (!mounted) return;

      final body = jsonDecode(res.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            body['message'] ??
                (res.statusCode == 200 ? 'Klaim berhasil' : 'Gagal klaim'),
          ),
          backgroundColor: res.statusCode == 200 ? Colors.green : Colors.red,
        ),
      );

      if (res.statusCode == 200) {
        _fetchMissions(); // Refresh mission data
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan jaringan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  void _showHowXpWorks() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Cara Kerja XP',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'XP (Experience Points) hanya didapatkan dengan menyelesaikan misi harian (seperti login harian, menyelesaikan bacaan episode, atau berkomentar). XP tidak bisa dibeli dengan Coins.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Gunakan XP untuk menaikkan Level kamu, memanjat Leaderboard Top XP, dan memprioritaskan komentarmu agar selalu tampil paling atas!',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Misi Harian')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Gagal memuat misi'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMissions,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Misi Harian & XP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHowXpWorks,
            tooltip: 'Cara Kerja XP',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMissions,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _missions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final m = _missions[index];
            final title = m['title'] ?? '';
            final desc = m['description'] ?? '';
            final xpReward = m['xp_reward'] ?? 0;
            final claimsToday = m['claims_today'] ?? 0;
            final dailyLimit = m['daily_limit'];
            final canClaim = m['can_claim'] == true;
            final isOnCooldown = m['is_on_cooldown'] == true;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withAlpha(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, color: Colors.amber),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '+$xpReward XP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              if (dailyLimit != null) ...[
                                const SizedBox(width: 12),
                                Text(
                                  '$claimsToday/$dailyLimit hari ini',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: (!canClaim || _isClaiming)
                          ? null
                          : () => _claimMission(m['code']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canClaim
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        foregroundColor: canClaim
                            ? Colors.white
                            : Colors.grey[600],
                        elevation: canClaim ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isClaiming && canClaim /* simplistic check */
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isOnCooldown
                                  ? 'Tunggu'
                                  : (canClaim ? 'Klaim' : 'Selesai'),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
