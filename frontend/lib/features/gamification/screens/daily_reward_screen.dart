import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({super.key});

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen> {
  Map<String, dynamic> _data = {};
  bool _isLoading = true;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final res = await ApiService.get(ApiEndpoints.dailyStatus);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _data = json;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _claimReward() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);
    try {
      final res = await ApiService.post(ApiEndpoints.dailyReward, {});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 +${json['coins_earned']} Coins, +${json['xp_earned']} XP (Streak: ${json['streak']})',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _fetchStatus(); // Refresh
        }
      } else {
        final json = jsonDecode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(json['message'] ?? 'Gagal klaim'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isClaiming = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = _data['level'] ?? 1;
    final exp = _data['exp_points'] ?? 0;
    final coins = _data['coins'] ?? 0;
    final streak = _data['streak'] ?? 0;
    final claimedToday = _data['claimed_today'] == true;
    final nextReward = _data['next_reward'] ?? 15;
    final weekDays = (_data['week_days'] ?? []) as List;

    final xpForNext = level * 1000;
    final progress = xpForNext > 0 ? (exp / xpForNext).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Rewards',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Level Card ───
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withAlpha(180),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$level',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level $level',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$exp / $xpForNext XP • $coins Coins',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white24,
                                    color: Colors.white,
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Daily Check-in ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Check-in',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '🔥 Streak: $streak',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      claimedToday
                          ? 'Sudah diklaim hari ini!'
                          : 'Klaim sekarang untuk +$nextReward coins!',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),

                    // ─── Week Grid ───
                    if (weekDays.isNotEmpty)
                      Row(
                        children: weekDays.map<Widget>((day) {
                          final claimed = day['claimed'] == true;
                          final dayLabel = day['day'] ?? '';
                          final isToday =
                              day['date'] ==
                              DateTime.now().toIso8601String().substring(0, 10);

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: claimed
                                    ? theme.primaryColor
                                    : (isToday
                                          ? theme.primaryColor.withAlpha(20)
                                          : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                                border: isToday && !claimed
                                    ? Border.all(
                                        color: theme.primaryColor,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    claimed
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: claimed
                                        ? Colors.white
                                        : (isToday
                                              ? theme.primaryColor
                                              : Colors.grey[400]),
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dayLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: claimed
                                          ? Colors.white
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),

                    // ─── Claim Button ───
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: claimedToday || _isClaiming
                            ? null
                            : _claimReward,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          claimedToday
                              ? '✅ Sudah Diklaim'
                              : (_isClaiming
                                    ? 'Claiming...'
                                    : '🎁 Klaim Reward (+$nextReward coins)'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
