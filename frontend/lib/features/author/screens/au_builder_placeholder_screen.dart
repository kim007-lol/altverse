import 'package:flutter/material.dart';

class AuBuilderPlaceholderScreen extends StatelessWidget {
  const AuBuilderPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AU Builder'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Colors.grey[900],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 48,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Buat cerita berbasis chat langsung di app!\n'
                'WA, Twitter, Instagram style — semua bisa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Feature chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _featureChip('💬 Fake WhatsApp', theme),
                  _featureChip('🐦 Fake Twitter', theme),
                  _featureChip('📸 Fake Instagram', theme),
                  _featureChip('✨ Custom Chat', theme),
                ],
              ),
              const SizedBox(height: 40),

              // Back button
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Kembali'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _featureChip(String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor.withAlpha(40)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: theme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
