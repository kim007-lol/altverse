// author_guide_screen.dart
import 'package:flutter/material.dart';

class AuthorGuideScreen extends StatelessWidget {
  const AuthorGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Author Guide'), backgroundColor: theme.scaffoldBackgroundColor, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withAlpha(178)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Panduan Author',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pelajari sistem tier, benefit, dan cara memaksimalkan potensi Anda sebagai author di AU Reader',
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Navigation
            _buildSectionTitle('Quick Navigation', Icons.explore_outlined, theme.primaryColor),
            const SizedBox(height: 12),
            _buildQuickNavCard(
              context,
              'Sistem Tier',
              'Pelajari 4 level tier dan cara naik tier',
              Icons.military_tech_outlined,
              Colors.amber,
              () => _scrollToSection(context, _tierSystemKey),
            ),
            _buildQuickNavCard(
              context,
              'Benefit per Tier',
              'Lihat fitur eksklusif setiap tier',
              Icons.card_giftcard_outlined,
              Colors.purple,
              () => _scrollToSection(context, _benefitsKey),
            ),
            _buildQuickNavCard(
              context,
              'Cara Naik Tier',
              'Tips dan strategi untuk upgrade tier',
              Icons.trending_up_outlined,
              Colors.green,
              () => _scrollToSection(context, _tipsKey),
            ),
            _buildQuickNavCard(
              context,
              'Monetisasi',
              'Cara menghasilkan uang dari karya Anda',
              Icons.monetization_on_outlined,
              Colors.orange,
              () => _scrollToSection(context, _monetizationKey),
            ),
            const SizedBox(height: 32),

            // Tier System Section
            _buildSectionTitle('Sistem Tier Author', Icons.military_tech_outlined, Colors.amber, key: _tierSystemKey),
            const SizedBox(height: 12),
            _buildInfoCard(
              theme,
              'Apa itu Tier System?',
              'Sistem tier adalah sistem penghargaan yang memberikan pengakuan dan benefit khusus kepada author berdasarkan performa dan pencapaian mereka. Semakin aktif dan sukses, semakin tinggi tier Anda!',
              Icons.info_outline,
              Colors.blue,
            ),
            const SizedBox(height: 16),

            // Tier Cards
            _buildTierCard(
              theme,
              'Bronze',
              Icons.local_fire_department_outlined,
              'Tier Awal',
              const Color(0xFFCD7F32),
              [
                'Tier default untuk semua author baru',
                'Akses dasar untuk membuat dan publish series',
                'Tidak ada requirement khusus',
              ],
              [],
            ),
            _buildTierCard(
              theme,
              'Silver',
              Icons.bolt_outlined,
              'Tier Menengah',
              const Color(0xFFC0C0C0),
              ['100+ Followers', '100+ Total Views'],
              ['🎨 Banner Customization', 'Bisa customize banner profile'],
            ),
            _buildTierCard(
              theme,
              'Gold',
              Icons.auto_awesome,
              'Tier Tinggi',
              const Color(0xFFFFD700),
              ['500+ Followers', '1,000+ Total Views'],
              ['🎨 Banner Customization', '💰 Tipping Enabled', 'Reader bisa mengirim tip langsung'],
            ),
            _buildTierCard(
              theme,
              'Diamond',
              Icons.diamond_outlined,
              'Tier Sangat Tinggi',
              const Color(0xFFB9F2FF),
              ['2,000+ Followers', '5,000+ Total Views'],
              [
                '🎨 Banner Customization',
                '💰 Tipping Enabled',
                'Reader bisa mengirim tip langsung',
                '💎 Exclusive Diamond Border',
                'Border kristal biru di profil Anda',
              ],
            ),
            _buildTierCard(
              theme,
              'Popular',
              Icons.verified,
              'Tier Tertinggi',
              Colors.blue[500]!,
              ['7,000+ Followers', '10,000+ Total Views'],
              [
                '🎨 Banner Customization',
                '💰 Tipping Enabled',
                '✅ Verified Badge',
                'Badge verifikasi resmi',
                '⭐ Priority Placement (coming soon)',
              ],
            ),
            const SizedBox(height: 32),

            // Benefits Section
            _buildSectionTitle('Benefit Detail', Icons.card_giftcard_outlined, Colors.purple, key: _benefitsKey),
            const SizedBox(height: 12),

            _buildBenefitDetailCard(
              theme,
              '🎨 Banner Customization',
              'Silver+',
              'Upload gambar header custom di profile Anda untuk branding personal dan tampilan lebih profesional. Banner akan terlihat oleh semua pengunjung profile.',
              Colors.pink,
            ),
            _buildBenefitDetailCard(
              theme,
              '💰 Tipping System',
              'Gold+',
              'Reader bisa mengirim tip (koin) langsung ke Anda sebagai bentuk apresiasi. Tip masuk langsung ke wallet dan bisa ditarik kapan saja.',
              Colors.orange,
            ),
            _buildBenefitDetailCard(
              theme,
              '✅ Verified Badge',
              'Popular',
              'Badge verifikasi resmi yang menunjukkan Anda adalah author terpercaya dan populer. Meningkatkan kredibilitas dan trust dari reader.',
              Colors.blue,
            ),
            const SizedBox(height: 32),

            // Tips Section
            _buildSectionTitle('Cara Naik Tier', Icons.trending_up_outlined, Colors.green, key: _tipsKey),
            const SizedBox(height: 12),

            _buildTipsCard(theme, 'Bronze → Silver', [
              'Fokus publish episode berkualitas',
              'Promosikan series di social media',
              'Engage dengan reader melalui comments',
              'Target: 100 followers & 100 views',
            ], Colors.teal),
            _buildTipsCard(theme, 'Silver → Gold', [
              'Konsisten publish episode baru',
              'Build loyal fanbase',
              'Fokus pada quality content untuk views organik',
              'Target: 500 followers & 1,000 views',
            ], Colors.amber),
            _buildTipsCard(theme, 'Gold → Diamond', [
              'Pertahankan views yang tinggi',
              'Tingkatkan interaksi dengan pembaca',
              'Fokus pada quality content',
              'Target: 2,000 followers & 5,000 views',
            ], Colors.cyan),
            _buildTipsCard(theme, 'Diamond → Popular', [
              'Maintain consistency dalam publishing',
              'Promosikan karya Anda secara masif',
              'Grow fanbase & leverage tipping feature',
              'Target: 7,000 followers & 100,000 views',
            ], Colors.purple),
            const SizedBox(height: 32),

            // Monetization Section
            _buildSectionTitle(
              'Sistem Monetisasi',
              Icons.monetization_on_outlined,
              Colors.orange,
              key: _monetizationKey,
            ),
            const SizedBox(height: 12),

            _buildMonetizationCard(
              theme,
              'Premium Episodes',
              'Semua Tier',
              'Set episode sebagai premium dan reader harus unlock dengan koin. Anda mendapat 80% dari harga unlock.',
              Icons.lock_outline,
              Colors.blue,
            ),
            _buildMonetizationCard(
              theme,
              'Tipping',
              'Gold+',
              'Reader bisa mengirim tip langsung ke Anda. 100% tip masuk ke wallet Anda tanpa potongan.',
              Icons.volunteer_activism_outlined,
              Colors.pink,
            ),
            _buildMonetizationCard(
              theme,
              'Withdrawal',
              'Semua Tier',
              'Tarik dana dari wallet ke rekening bank. Minimum withdrawal: 10,000 koin (≈ Rp 800,000).',
              Icons.account_balance_wallet_outlined,
              Colors.green,
            ),
            const SizedBox(height: 32),

            // FAQ Section
            _buildSectionTitle('Frequently Asked Questions', Icons.help_outline, Colors.indigo),
            const SizedBox(height: 12),

            _buildFAQCard(
              theme,
              'Berapa lama waktu untuk naik tier?',
              'Tier dihitung otomatis oleh sistem. Begitu Anda memenuhi semua requirement, tier akan naik secara otomatis dalam beberapa menit.',
            ),
            _buildFAQCard(
              theme,
              'Apakah tier bisa turun?',
              'Tidak, tier tidak akan turun. Sekali Anda mencapai tier tertentu, benefit akan tetap aktif meskipun statistik turun.',
            ),
            _buildFAQCard(
              theme,
              'Bagaimana cara melihat progress tier?',
              'Buka Analytics screen, di sana Anda bisa melihat tier saat ini dan progress menuju tier berikutnya dengan detail.',
            ),
            _buildFAQCard(
              theme,
              'Apakah ada biaya untuk naik tier?',
              'Tidak ada biaya sama sekali! Tier system sepenuhnya gratis dan berdasarkan performa Anda.',
            ),
            const SizedBox(height: 32),

            // Call to Action
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Siap Memulai?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mulai publish episode berkualitas dan bangun fanbase Anda. Tier yang lebih tinggi menanti!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kembali ke Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Section keys for scrolling
  static final GlobalKey _tierSystemKey = GlobalKey();
  static final GlobalKey _benefitsKey = GlobalKey();
  static final GlobalKey _tipsKey = GlobalKey();
  static final GlobalKey _monetizationKey = GlobalKey();

  void _scrollToSection(BuildContext context, GlobalKey key) {
    Scrollable.ensureVisible(key.currentContext!, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color, {Key? key}) {
    return Row(
      key: key,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(38), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickNavCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(76)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(38), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                ),
                const SizedBox(height: 6),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(
    ThemeData theme,
    String tierName,
    IconData tierIcon,
    String tierLevel,
    Color color,
    List<String> requirements,
    List<String> benefits,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(150), width: 2),
        boxShadow: [BoxShadow(color: color.withAlpha(40), blurRadius: 12, spreadRadius: 2, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tierIcon, color: color, size: 28),
              const SizedBox(width: 8),
              Text(
                tierName,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withAlpha(38), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  tierLevel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Requirements
          Text(
            'Requirements:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          ...requirements.map(
            (req) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(req, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ),
                ],
              ),
            ),
          ),

          // Benefits
          if (benefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Benefits:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            ...benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(benefit, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitDetailCard(ThemeData theme, String title, String tierRequired, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withAlpha(38), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  tierRequired,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTipsCard(ThemeData theme, String title, List<String> tips, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 10),
          ...tips.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: color.withAlpha(38), shape: BoxShape.circle),
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.value, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonetizationCard(
    ThemeData theme,
    String title,
    String availability,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(38), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withAlpha(38), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        availability,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(ThemeData theme, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline, size: 20, color: Colors.indigo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(answer, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
          ),
        ],
      ),
    );
  }
}
