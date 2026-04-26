import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ThemeColorScreen extends StatefulWidget {
  const ThemeColorScreen({super.key});

  @override
  State<ThemeColorScreen> createState() => _ThemeColorScreenState();
}

class _ThemeColorScreenState extends State<ThemeColorScreen> {
  Color _selectedColor = const Color(0xFFC084FC);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _selectedColor = auth.primaryColor;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.updateThemeColor(_selectedColor);
    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: theme.scaffoldBackgroundColor, elevation: 0, title: const Text('Tema Aplikasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Light / Dark Toggle ───
            _buildThemeModeSection(theme, auth),
            const SizedBox(height: 28),

            // ─── Divider ───
            Divider(color: theme.dividerColor, height: 1),
            const SizedBox(height: 28),

            // ─── Color Section Header ───
            Text(
              'Warna Aksen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih warna aksen untuk tombol & elemen interaktif',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),

            // ─── Preview Card ───
            _buildPreview(theme, auth.isDarkMode),
            const SizedBox(height: 28),

            // ─── Color Grid ───
            Text(
              'Warna Tersedia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 16),
            _buildColorGrid(),
            const SizedBox(height: 32),

            // ─── Save Button ───
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan Warna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Light / Dark Mode Toggle ───
  Widget _buildThemeModeSection(ThemeData theme, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode Tampilan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 4),
          Text('Pilih tampilan terang atau gelap', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 16),
          Row(
            children: [
              // Dark Mode Option
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!auth.isDarkMode) auth.toggleThemeMode();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: auth.isDarkMode ? _selectedColor.withAlpha(25) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: auth.isDarkMode ? _selectedColor : Colors.grey.withAlpha(50),
                        width: auth.isDarkMode ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.dark_mode_rounded,
                          size: 28,
                          color: auth.isDarkMode ? _selectedColor : Colors.grey[500],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gelap',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: auth.isDarkMode ? FontWeight.w700 : FontWeight.w500,
                            color: auth.isDarkMode ? _selectedColor : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Light Mode Option
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (auth.isDarkMode) auth.toggleThemeMode();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: !auth.isDarkMode ? _selectedColor.withAlpha(25) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !auth.isDarkMode ? _selectedColor : Colors.grey.withAlpha(50),
                        width: !auth.isDarkMode ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.light_mode_rounded,
                          size: 28,
                          color: !auth.isDarkMode ? _selectedColor : Colors.grey[500],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Terang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: !auth.isDarkMode ? FontWeight.w700 : FontWeight.w500,
                            color: !auth.isDarkMode ? _selectedColor : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),

          // Sample buttons
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Tombol Utama'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _selectedColor,
                    side: BorderSide(color: _selectedColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Sekunder'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sample chips
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: const Text('Fantasy'),
                backgroundColor: _selectedColor.withAlpha(30),
                labelStyle: TextStyle(color: _selectedColor, fontWeight: FontWeight.w600, fontSize: 12),
                side: BorderSide.none,
              ),
              Chip(
                label: const Text('Romance'),
                backgroundColor: _selectedColor.withAlpha(30),
                labelStyle: TextStyle(color: _selectedColor, fontWeight: FontWeight.w600, fontSize: 12),
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sample progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.65,
              backgroundColor: _selectedColor.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(_selectedColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('Progress: 65%', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildColorGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: AppTheme.presetColors.length,
      itemBuilder: (context, i) {
        final preset = AppTheme.presetColors[i];
        final color = preset['color'] as Color;
        final name = preset['name'] as String;
        final isSelected = _selectedColor.toARGB32() == color.toARGB32();

        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 60 : 52,
                height: isSelected ? 60 : 52,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withAlpha(100), blurRadius: 12, spreadRadius: 2)]
                      : null,
                  border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 28) : null,
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
