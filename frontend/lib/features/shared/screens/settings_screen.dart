import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_provider.dart';
import '../../reader/screens/theme_color_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _appVersion = '2.0.0';
  static const String _prefKeyPushNotif = 'pref_push_notifications';
  static const String _prefKeyMissionAlert = 'pref_mission_alerts';

  bool _pushEnabled = true;
  bool _missionAlerts = true;
  bool _togglingTheme = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushEnabled = prefs.getBool(_prefKeyPushNotif) ?? true;
      _missionAlerts = prefs.getBool(_prefKeyMissionAlert) ?? true;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _toggleDarkMode(AuthProvider auth) async {
    if (_togglingTheme) return;
    setState(() => _togglingTheme = true);
    await auth.toggleThemeMode();
    if (mounted) setState(() => _togglingTheme = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ─── Appearance ───────────────────────────────
          _sectionHeader(theme, 'Appearance'),
          _buildSwitchTile(
            theme: theme,
            icon: Icons.dark_mode_rounded,
            iconColor: Colors.indigo[400]!,
            title: 'Dark Mode',
            subtitle: auth.isDarkMode ? 'Currently dark' : 'Currently light',
            value: auth.isDarkMode,
            onChanged: _togglingTheme ? null : (_) => _toggleDarkMode(auth),
          ),
          _buildNavTile(
            theme: theme,
            icon: Icons.palette_rounded,
            iconColor: Colors.purple[400]!,
            title: 'Accent Color',
            subtitle: 'Customize app accent color',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemeColorScreen()),
            ),
          ),

          const SizedBox(height: 8),

          // ─── Notifications ─────────────────────────────
          _sectionHeader(theme, 'Notifications'),
          _buildSwitchTile(
            theme: theme,
            icon: Icons.notifications_rounded,
            iconColor: Colors.amber[700]!,
            title: 'Push Notifications',
            subtitle: 'New chapters, follows, and updates',
            value: _pushEnabled,
            onChanged: (val) {
              setState(() => _pushEnabled = val);
              _setPref(_prefKeyPushNotif, val);
            },
          ),
          _buildSwitchTile(
            theme: theme,
            icon: Icons.track_changes_rounded,
            iconColor: Colors.green[600]!,
            title: 'Mission Alerts',
            subtitle: 'Notify when a mission is ready to claim',
            value: _missionAlerts,
            onChanged: (val) {
              setState(() => _missionAlerts = val);
              _setPref(_prefKeyMissionAlert, val);
            },
          ),

          const SizedBox(height: 8),

          // ─── About ────────────────────────────────────
          _sectionHeader(theme, 'About'),
          _buildInfoTile(
            theme: theme,
            icon: Icons.info_outline_rounded,
            iconColor: Colors.grey[600]!,
            title: 'App Version',
            trailing: Text(
              _appVersion,
              style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: theme.primaryColor),
      ),
    );
  }

  Widget _buildSwitchTile({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: theme.primaryColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _buildNavTile({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _buildInfoTile({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
