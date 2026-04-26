import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';

class BadgeCollectionScreen extends StatefulWidget {
  const BadgeCollectionScreen({super.key});

  @override
  State<BadgeCollectionScreen> createState() => _BadgeCollectionScreenState();
}

class _BadgeCollectionScreenState extends State<BadgeCollectionScreen> {
  bool _isLoading = true;
  List<dynamic> _earnedBadges = [];
  List<dynamic> _lockedBadges = [];
  String _selectedCategory = 'all';

  static const _categories = [
    {'key': 'all', 'label': 'All', 'icon': Icons.grid_view},
    {'key': 'reading', 'label': 'Reading', 'icon': Icons.menu_book},
    {'key': 'social', 'label': 'Social', 'icon': Icons.people},
    {'key': 'creator', 'label': 'Creator', 'icon': Icons.create},
    {'key': 'special', 'label': 'Special', 'icon': Icons.star},
  ];

  @override
  void initState() {
    super.initState();
    _fetchBadges();
  }

  Future<void> _fetchBadges() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get(ApiEndpoints.badges);
      if (res.success && mounted) {
        final badges = (res.data['badges'] as List?) ?? [];

        // Separate earned and locked badges
        final earned = badges.where((b) => b['earned_at'] != null).toList();
        final locked = badges.where((b) => b['earned_at'] == null).toList();

        setState(() {
          _earnedBadges = earned;
          _lockedBadges = locked;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getFilteredBadges(List<dynamic> badges) {
    if (_selectedCategory == 'all') return badges;
    return badges.where((b) => b['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredEarned = _getFilteredBadges(_earnedBadges);
    final filteredLocked = _getFilteredBadges(_lockedBadges);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Badge Collection'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchBadges,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Stats Summary
                    _buildStatsSummary(theme),

                    const SizedBox(height: 20),

                    // Category Filter
                    _buildCategoryFilter(theme),

                    const SizedBox(height: 20),

                    // Earned Badges
                    if (filteredEarned.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events, size: 20, color: theme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Earned Badges',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${filteredEarned.length}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBadgeGrid(filteredEarned, theme, isEarned: true),
                    ],

                    // Locked Badges
                    if (filteredLocked.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, size: 20, color: Colors.grey[400]),
                            const SizedBox(width: 8),
                            Text(
                              'Locked Badges',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${filteredLocked.length}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBadgeGrid(filteredLocked, theme, isEarned: false),
                    ],

                    // Empty State
                    if (filteredEarned.isEmpty && filteredLocked.isEmpty) _buildEmptyState(theme),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsSummary(ThemeData theme) {
    final totalBadges = _earnedBadges.length + _lockedBadges.length;
    final earnedCount = _earnedBadges.length;
    final progress = totalBadges > 0 ? (earnedCount / totalBadges) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.emoji_events,
                label: 'Earned',
                value: '$earnedCount',
                color: theme.primaryColor,
              ),
              Container(width: 1, height: 40, color: Colors.grey.withAlpha(50)),
              _buildStatItem(
                icon: Icons.lock_outline,
                label: 'Locked',
                value: '${_lockedBadges.length}',
                color: Colors.grey[400]!,
              ),
              Container(width: 1, height: 40, color: Colors.grey.withAlpha(50)),
              _buildStatItem(icon: Icons.grid_view, label: 'Total', value: '$totalBadges', color: Colors.blue[400]!),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.withAlpha(25),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% Complete',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat['key'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat['key'] as String);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? theme.primaryColor : Colors.grey.withAlpha(50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat['icon'] as IconData, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeGrid(List<dynamic> badges, ThemeData theme, {required bool isEarned}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: badges.length,
        itemBuilder: (context, i) {
          final badge = badges[i];
          return _buildBadgeCard(badge, theme, isEarned: isEarned);
        },
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge, ThemeData theme, {required bool isEarned}) {
    final bColor = AppTheme.getColorFromHex(badge['color']);
    final icon = badge['icon'] ?? '🏆';

    return GestureDetector(
      onTap: () => _showBadgeDetail(badge, theme, isEarned),
      child: Container(
        decoration: BoxDecoration(
          color: isEarned ? bColor.withAlpha(15) : Colors.grey.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isEarned ? bColor.withAlpha(50) : Colors.grey.withAlpha(50), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(icon, style: TextStyle(fontSize: 40, color: isEarned ? null : Colors.grey[400])),
                if (!isEarned) Icon(Icons.lock, size: 24, color: Colors.grey[600]),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                badge['name'] ?? '',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isEarned ? bColor : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No badges found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text('Try selecting a different category', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(Map<String, dynamic> badge, ThemeData theme, bool isEarned) {
    final bColor = AppTheme.getColorFromHex(badge['color']);
    final icon = badge['icon'] ?? '🏆';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),

            // Badge Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isEarned ? bColor.withAlpha(15) : Colors.grey.withAlpha(15),
                shape: BoxShape.circle,
                border: Border.all(color: isEarned ? bColor.withAlpha(50) : Colors.grey.withAlpha(50), width: 3),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(icon, style: TextStyle(fontSize: 50, color: isEarned ? null : Colors.grey[400])),
                    if (!isEarned) Icon(Icons.lock, size: 32, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Badge Name
            Text(
              badge['name'] ?? '',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isEarned ? bColor : Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Badge Description
            Text(
              badge['description'] ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            // Earned Date or Requirement
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.grey.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEarned ? Icons.check_circle : Icons.lock_clock,
                    size: 16,
                    color: isEarned ? Colors.green : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEarned ? 'Earned: ${badge['earned_at'] ?? 'Unknown'}' : 'Complete the requirement to unlock',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Close Button
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
                child: const Text('Close', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
