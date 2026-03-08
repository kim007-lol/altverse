import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

class TierBenefitScreen extends StatefulWidget {
  const TierBenefitScreen({super.key});

  @override
  State<TierBenefitScreen> createState() => _TierBenefitScreenState();
}

class _TierBenefitScreenState extends State<TierBenefitScreen> {
  Map<String, dynamic> _data = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await ApiService.get(ApiEndpoints.tierProgress);
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _data = jsonDecode(res.body);
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTier = _data['current_tier'] ?? 'bronze';
    final currentBenefits = List<String>.from(_data['current_benefits'] ?? []);
    final allBenefits = (_data['all_benefits'] as Map<String, dynamic>?) ?? {};
    final progress = (_data['progress'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tiers & Benefits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Current Tier Card ───
                    _buildCurrentTierCard(currentTier, currentBenefits, theme),
                    const SizedBox(height: 24),

                    // ─── All Tiers ───
                    const Text(
                      'All Tiers',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildTierCards(
                      currentTier,
                      allBenefits,
                      progress,
                      theme,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentTierCard(
    String tier,
    List<String> benefits,
    ThemeData theme,
  ) {
    final emoji = _tierEmoji(tier);
    final name = _capitalize(tier);
    final color = _tierColor(tier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(40), color.withAlpha(15)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Tier',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '$name Tier',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (benefits.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Active Benefits',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: benefits.map((b) {
                final label = _benefitLabel(b);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Upgrade untuk membuka benefit!',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildTierCards(
    String currentTier,
    Map<String, dynamic> allBenefits,
    Map<String, dynamic> progress,
    ThemeData theme,
  ) {
    final tierOrder = ['bronze', 'silver', 'gold', 'popular'];
    final currentIdx = tierOrder.indexOf(currentTier);

    return tierOrder.map((tier) {
      final idx = tierOrder.indexOf(tier);
      final isActive = idx <= currentIdx;
      final isCurrent = tier == currentTier;
      final emoji = _tierEmoji(tier);
      final name = _capitalize(tier);
      final color = _tierColor(tier);
      final benefits = List<String>.from(allBenefits[tier] ?? []);
      final tierProgress = progress[tier] as Map<String, dynamic>?;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent ? color.withAlpha(10) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isCurrent
              ? Border.all(color: color.withAlpha(80), width: 2)
              : Border.all(color: Colors.grey.withAlpha(25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✅ Unlocked',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (benefits.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...benefits.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 14, color: Colors.green[400]),
                      const SizedBox(width: 6),
                      Text(
                        _benefitLabel(b),
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Progress bars for next tier
            if (tierProgress != null && !isActive) ...[
              const SizedBox(height: 10),
              ..._buildReqProgress(
                tierProgress['requirements'] as Map<String, dynamic>? ?? {},
                theme,
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildReqProgress(
    Map<String, dynamic> requirements,
    ThemeData theme,
  ) {
    return requirements.entries.map((entry) {
      final key = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final required = data['required'];
      final current = data['current'];
      final met = data['met'] == true;

      final label = _reqLabel(key);

      if (required is bool) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                met ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 14,
                color: met ? Colors.green : Colors.grey[400],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        );
      } else {
        final reqNum = (required as num).toDouble();
        final curNum = (current as num?)?.toDouble() ?? 0;
        final progress = (curNum / reqNum).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
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
                    '${_fmtNum(curNum)} / ${_fmtNum(reqNum)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: met ? Colors.green : Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: met ? Colors.green : theme.primaryColor,
                  minHeight: 5,
                ),
              ),
            ],
          ),
        );
      }
    }).toList();
  }

  // ── Helpers ──
  String _tierEmoji(String tier) => switch (tier) {
    'popular' => '👑',
    'gold' => '🥇',
    'silver' => '🥈',
    _ => '🥉',
  };

  Color _tierColor(String tier) => switch (tier) {
    'popular' => Colors.purple,
    'gold' => Colors.amber,
    'silver' => Colors.blueGrey,
    _ => Colors.brown,
  };

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _benefitLabel(String b) => switch (b) {
    'can_customize_banner' => '🎨 Custom Banner',
    'can_tip' => '💰 Tipping',
    'is_verified' => '✅ Verified',
    _ => b,
  };

  String _reqLabel(String key) => switch (key) {
    'followers' => '👥 Followers',
    'published_episodes' => '📖 Published Episodes',
    'total_views' => '👁 Total Views',
    'has_archived_series' => '📚 Completed Series',
    _ => key,
  };

  String _fmtNum(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toInt().toString();
  }
}
