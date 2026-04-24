import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../features/reader/screens/home_screen.dart';
import '../../features/reader/screens/search_screen.dart';
import '../../features/reader/screens/library_screen.dart';
import '../../features/gamification/screens/leaderboard_screen.dart';
import '../../features/author/screens/dashboard_screen.dart';
import '../../features/author/screens/series_management_screen.dart';
import '../../features/author/screens/create_series_screen.dart';
import '../../features/author/screens/analytics_screen.dart';
import '../../features/author/screens/au_builder_placeholder_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/reader/screens/reader_profile_screen.dart';
import '../../features/reader/screens/author_profile_screen.dart';

class MasterScreen extends StatefulWidget {
  final String role;

  const MasterScreen({super.key, required this.role});

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  int _currentIndex =
      0; // Default landing = Home (reader) or Dashboard (author)
  String? _currentRole;
  final GlobalKey<AuthorDashboardScreenState> _dashboardKey = GlobalKey();
  int _draftCount = 0;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.role;
    if (widget.role == 'author') _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    try {
      final response = await ApiService.get(ApiEndpoints.authorSeriesCounts);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _draftCount = data['draft'] ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.isLoggedIn ? authProvider.role : widget.role;

    // If role changed (e.g., user switched role), reset index to 0
    if (_currentRole != null && _currentRole != role) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = 0;
            _currentRole = role;
          });
        }
      });
      if (role == 'author') _fetchCounts();
    }

    final isReader = role == 'reader';
    final theme = Theme.of(context);

    if (isReader) {
      return _buildReaderScaffold(role, theme);
    }
    return _buildAuthorScaffold(role, theme);
  }

  // ─── Reader Layout (unchanged) ───
  Widget _buildReaderScaffold(String role, ThemeData theme) {
    final tabs = _readerTabs(role);
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);
    return Scaffold(
      body: IndexedStack(index: safeIndex, children: tabs),
      bottomNavigationBar: NavigationBarTheme(
        data: _navBarThemeData(theme),
        child: NavigationBar(
          height: 70,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: _readerDestinations,
        ),
      ),
    );
  }

  // ─── Author Layout (5-tab: Dashboard, Series, FAB, Analytics, Profile) ───
  Widget _buildAuthorScaffold(String role, ThemeData theme) {
    final tabs = _authorTabs(role);
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);
    return Scaffold(
      body: IndexedStack(index: safeIndex, children: tabs),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadBottomSheet(context, theme),
        backgroundColor: theme.primaryColor,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: theme.scaffoldBackgroundColor,
        elevation: 0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AuthorNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isActive: safeIndex == 0,
                theme: theme,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _AuthorNavItem(
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book_rounded,
                label: 'Series',
                isActive: safeIndex == 1,
                badge: _draftCount > 0 ? _draftCount : null,
                theme: theme,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              const SizedBox(width: 48), // FAB placeholder
              _AuthorNavItem(
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics_rounded,
                label: 'Analytics',
                isActive: safeIndex == 2,
                theme: theme,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _AuthorNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: safeIndex == 3,
                theme: theme,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Upload FAB Bottom Sheet ───
  void _showUploadBottomSheet(BuildContext ctx, ThemeData theme) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Buat Konten Baru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Create New Series ───
              _BottomSheetOption(
                icon: Icons.add_circle_outline_rounded,
                title: 'Buat Series Baru',
                subtitle: 'Mulai seri baru dari awal',
                color: theme.primaryColor,
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateSeries();
                },
              ),
              const SizedBox(height: 8),

              // ─── Add Episode to Existing ───
              _BottomSheetOption(
                icon: Icons.post_add_rounded,
                title: 'Tambah Episode',
                subtitle: 'Tambah episode ke series yang ada',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(ctx);
                  // Navigate to Series tab (index 1) so author can choose
                  setState(() => _currentIndex = 1);
                },
              ),
              const SizedBox(height: 8),

              // ─── AU Builder (Coming Soon) ───
              _BottomSheetOption(
                icon: Icons.auto_awesome_rounded,
                title: 'AU Builder',
                subtitle: 'Chat-based stories (Coming Soon)',
                color: Colors.deepPurple,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Soon',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AuBuilderPlaceholderScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreateSeries() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSeriesScreen(
          onBack: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
    // Refresh dashboard and counts when returning
    _dashboardKey.currentState?.fetchDashboardData();
    _fetchCounts();
  }

  List<Widget> _readerTabs(String role) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['id'];
    return [
      const ReaderHomeScreen(),
      const SearchScreen(),
      const LeaderboardScreen(),
      const LibraryScreen(),
      userId != null
          ? ReaderProfileScreen(userId: userId)
          : const LoginScreen(),
    ];
  }

  List<Widget> _authorTabs(String role) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['id'];
    return [
      AuthorDashboardScreen(key: _dashboardKey),
      const SeriesManagementScreen(),
      const AnalyticsScreen(),
      userId != null
          ? AuthorProfileScreen(authorId: userId)
          : const LoginScreen(),
    ];
  }

  NavigationBarThemeData _navBarThemeData(ThemeData theme) {
    return NavigationBarThemeData(
      indicatorColor: theme.primaryColor.withAlpha(30),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.primaryColor,
          );
        }
        return TextStyle(fontSize: 11, color: Colors.grey[600]);
      }),
    );
  }

  static const _readerDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore_rounded),
      label: 'Discover',
    ),
    NavigationDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events_rounded),
      label: 'Ranking',
    ),
    NavigationDestination(
      icon: Icon(Icons.collections_bookmark_outlined),
      selectedIcon: Icon(Icons.collections_bookmark),
      label: 'Library',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];
}

// ─── Author Nav Item with Optional Badge ───
class _AuthorNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int? badge;
  final ThemeData theme;
  final VoidCallback onTap;

  const _AuthorNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    this.badge,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? theme.primaryColor : Colors.grey[500]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, color: color, size: 24),
                if (badge != null && badge! > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge! > 99 ? '99+' : badge!.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Sheet Option Item ───
class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.grey[400],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
