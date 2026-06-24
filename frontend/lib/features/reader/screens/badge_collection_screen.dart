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
  String _selectedFilter = 'all'; // 'all', 'earned', 'locked'

  static const _categories = [
    {'key': 'all', 'label': 'All', 'icon': Icons.grid_view},
    {'key': 'reader', 'label': 'Reader', 'icon': Icons.menu_book},
    {'key': 'author', 'label': 'Author', 'icon': Icons.create},
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

  Future<void> _togglePinBadge(Map<String, dynamic> badge) async {
    final badgeId = badge['id'];
    if (badgeId == null) return;

    try {
      final res = await ApiService.post(ApiEndpoints.pinBadge(badgeId));
      if (res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty ? res.message : 'Badge status updated!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _fetchBadges(); // Refresh to update pin state
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isNotEmpty ? res.message : 'Gagal pin badge'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal pin badge'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredEarned = _getFilteredBadges(_earnedBadges);
    final pinnedEarned = filteredEarned.where((b) => b['is_pinned'] == true).toList();
    final unpinnedEarned = filteredEarned.where((b) => b['is_pinned'] != true).toList();
    final filteredLocked = _getFilteredBadges(_lockedBadges);

    final showEarned = _selectedFilter == 'all' || _selectedFilter == 'earned';
    final showLocked = _selectedFilter == 'all' || _selectedFilter == 'locked';

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

                    // Category Filter (Reader / Author / All)
                    _buildCategoryFilter(theme),

                    const SizedBox(height: 12),

                    // Status Filter (All / Earned / Locked)
                    _buildStatusFilter(theme),

                    const SizedBox(height: 20),

                    // Pinned Badges
                    if (showEarned && pinnedEarned.isNotEmpty) ...[
                      _buildSectionHeader(
                        theme,
                        icon: Icons.push_pin,
                        label: 'Pinned Badges',
                        count: pinnedEarned.length,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildBadgeGrid(pinnedEarned, theme, isEarned: true),
                      const SizedBox(height: 24),
                    ],

                    // Earned Badges
                    if (showEarned && unpinnedEarned.isNotEmpty) ...[
                      _buildSectionHeader(
                        theme,
                        icon: Icons.emoji_events,
                        label: 'Earned Badges',
                        count: unpinnedEarned.length,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _buildBadgeGrid(unpinnedEarned, theme, isEarned: true),
                    ],

                    // Locked Badges
                    if (showLocked && filteredLocked.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        theme,
                        icon: Icons.lock_outline,
                        label: 'Locked Badges',
                        count: filteredLocked.length,
                        color: Colors.grey[500]!,
                      ),
                      const SizedBox(height: 12),
                      _buildBadgeGrid(filteredLocked, theme, isEarned: false),
                    ],

                    // Empty State
                    if ((showEarned ? filteredEarned : []).isEmpty &&
                        (showLocked ? filteredLocked : []).isEmpty)
                      _buildEmptyState(theme),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Stats Summary ───
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
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  // ─── Category Filter (All / Reader / Author) ───
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
              onTap: () => setState(() => _selectedCategory = cat['key'] as String),
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

  // ─── Status Filter (All / Earned / Locked) ───
  Widget _buildStatusFilter(ThemeData theme) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'earned', 'label': 'Earned'},
      {'key': 'locked', 'label': 'Locked'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = f['key']!),
              selectedColor: theme.primaryColor.withAlpha(40),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? theme.primaryColor : Colors.grey[600],
              ),
              side: BorderSide(
                color: isSelected ? theme.primaryColor.withAlpha(80) : Colors.grey.withAlpha(50),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Section Header ───
  Widget _buildSectionHeader(ThemeData theme,
      {required IconData icon, required String label, required int count, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
            child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  // ─── Badge Grid ───
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
    final isPinned = badge['is_pinned'] == true;

    return GestureDetector(
      onTap: () => _showBadgeDetail(badge, theme, isEarned),
      child: Container(
        decoration: BoxDecoration(
          color: isEarned ? bColor.withAlpha(15) : Colors.grey.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPinned
                ? Colors.amber.withAlpha(150)
                : isEarned
                    ? bColor.withAlpha(50)
                    : Colors.grey.withAlpha(50),
            width: isPinned ? 2.5 : 2,
          ),
        ),
        child: Stack(
          children: [
            // Pin indicator
            if (isPinned)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.push_pin_rounded, size: 14, color: Colors.amber[700]),
              ),
            // Badge content
            Center(
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
            Text('No badges found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Try selecting a different category', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  // ─── Badge Detail Sheet ───
  void _showBadgeDetail(Map<String, dynamic> badge, ThemeData theme, bool isEarned) {
    final bColor = AppTheme.getColorFromHex(badge['color']);
    final icon = badge['icon'] ?? '🏆';
    final isPinned = badge['is_pinned'] == true;

    // Check if this is a lifetime badge (auto-pinned, can't manual pin)
    final key = badge['key'] ?? '';
    final isLifetimeBadge = key.startsWith('lifetime_');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                // Pin/Unpin Button (only for earned non-lifetime badges)
                if (isEarned && !isLifetimeBadge) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _togglePinBadge(badge);
                      },
                      icon: Icon(
                        isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                        size: 18,
                      ),
                      label: Text(isPinned ? 'Unpin' : 'Pin to Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isPinned ? Colors.amber[700] : theme.primaryColor,
                        side: BorderSide(color: isPinned ? Colors.amber.withAlpha(150) : theme.primaryColor.withAlpha(80)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Close Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
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
          ],
        ),
      ),
    );
  }
}
