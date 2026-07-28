import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const String _instagramUrl = 'https://www.instagram.com/aureader.id';
  static const String _emailContact = 'support@aureader.id';

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'How do I unlock a locked episode?',
      answer:
          'Locked episodes require coins to unlock. Top up your coin balance via the Wallet screen, then tap the locked episode to purchase access. Coins are non-expiring — any episode you unlock stays accessible forever on your account.',
    ),
    _FaqItem(
      question: 'How does the XP and leveling system work?',
      answer:
          'You earn XP by reading episodes, completing daily missions, and engaging with content (likes, comments). Each season resets the leaderboard. Your total level (shown on your profile) never resets — only the seasonal rank does.',
    ),
    _FaqItem(
      question: 'What are Supporter tiers?',
      answer:
          'Supporter tiers (Bronze → Silver → Gold → Diamond) are determined by how many coins you have spent on authors in the current season. Higher tiers unlock a badge displayed next to your name on leaderboards and author supporter lists.',
    ),
    _FaqItem(
      question: 'How do I complete missions?',
      answer:
          'Open the Missions screen from the bottom navigation. Active missions show your progress automatically as you use the app. Once a mission is at 100%, tap "Claim" to collect your XP and coin rewards. Some missions reset daily.',
    ),
    _FaqItem(
      question: 'Can I withdraw my author earnings?',
      answer:
          'Authors can request a withdrawal from the Author Dashboard → Wallet section once their balance meets the minimum threshold. Withdrawals are processed manually by the admin team within 1–3 business days.',
    ),
    _FaqItem(
      question: 'Why is my coin balance not updating?',
      answer:
          'After a top-up, pull to refresh the Wallet screen. If the balance still does not update after 60 seconds, contact support — Midtrans payment webhooks occasionally have delays during peak hours.',
    ),
    _FaqItem(
      question: 'How do I report inappropriate content?',
      answer:
          'On any series or episode page, tap the three-dot menu (⋮) and select "Report". Submitted reports are reviewed by moderators within 24 hours. You can track your submitted reports under Profile → My Reports.',
    ),
  ];

  final Map<int, bool> _expanded = {};

  Future<void> _openInstagram() async {
    final uri = Uri.parse(_instagramUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Instagram')),
        );
      }
    }
  }

  Future<void> _sendEmail() async {
    final uri = Uri(scheme: 'mailto', path: _emailContact, queryParameters: {
      'subject': 'AU Reader Support Request',
    });
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send email to $_emailContact')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Help Center', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ─── Banner ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.primaryColor.withAlpha(20), theme.primaryColor.withAlpha(5)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.primaryColor.withAlpha(40)),
            ),
            child: Row(
              children: [
                Icon(Icons.support_agent_rounded, size: 40, color: theme.primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('How can we help?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Browse the FAQ below or reach us via Instagram or email.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── FAQ ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: theme.primaryColor),
            ),
          ),
          ...List.generate(_faqs.length, (i) {
            final isOpen = _expanded[i] ?? false;
            final faq = _faqs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isOpen ? theme.primaryColor.withAlpha(60) : Colors.grey.withAlpha(30)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _expanded[i] = !isOpen),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              faq.question,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isOpen ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          Icon(
                            isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: isOpen ? theme.primaryColor : Colors.grey[400],
                            size: 22,
                          ),
                        ],
                      ),
                      if (isOpen) ...[
                        const SizedBox(height: 10),
                        Text(
                          faq.answer,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // ─── Contact ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'CONTACT US',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: theme.primaryColor),
            ),
          ),
          _buildContactTile(
            theme: theme,
            icon: Icons.camera_alt_outlined,
            iconColor: Colors.pink[400]!,
            title: 'Instagram',
            subtitle: '@aureader.id',
            onTap: _openInstagram,
          ),
          _buildContactTile(
            theme: theme,
            icon: Icons.email_outlined,
            iconColor: Colors.blue[400]!,
            title: 'Email Support',
            subtitle: _emailContact,
            onTap: _sendEmail,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(30)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: Icon(Icons.open_in_new_rounded, color: Colors.grey[400], size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
