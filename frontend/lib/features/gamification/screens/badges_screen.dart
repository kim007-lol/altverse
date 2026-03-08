import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _earnedBadges = [];
  bool _isPinning = false;

  @override
  void initState() {
    super.initState();
    _fetchBadges();
  }

  Future<void> _fetchBadges() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final res = await ApiService.get(ApiEndpoints.badges);
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        setState(() {
          _earnedBadges = body['earned'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _togglePin(int userBadgeId) async {
    if (_isPinning) return;
    setState(() => _isPinning = true);

    try {
      final res = await ApiService.post(ApiEndpoints.pinBadge(userBadgeId), {});

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Berhasil mengubah pin'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchBadges();
      } else {
        final body = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Gagal mengubah pin'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan jaringan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPinning = false);
    }
  }

  void _showHowBadgesWork() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Cara Kerja Badges',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Terdapat dua jenis Badges yang akan tampil di sebelah namamu:',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Lifetime Supporter Badge (Auto-Pinned) \nBadge eksklusif ini otomatis di-pin berdasarkan total dukungan seumur hidupmu.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '2. Custom Badge \nKamu bisa memilih 1 badge ekstra dari seluruh koleksi yang telah kamu dapatkan untuk ditampilkan.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Badges')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Gagal memuat badges'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchBadges,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koleksi Badges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHowBadgesWork,
            tooltip: 'Cara Kerja Badges',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBadges,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Badge Dimiliki',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih maks 1 custom badge untuk ditampilkan bersama Lifetime Badge kamu.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (_earnedBadges.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.military_tech,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada badge',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _earnedBadges.length,
                  itemBuilder: (context, i) {
                    final ub = _earnedBadges[i];
                    final badge = ub['badge'] ?? ub;
                    final isPinned = ub['is_pinned'] == true;
                    // Auto-pinned highest lifetime badge shouldn't have unpin button if condition_type == 'spend'.
                    // Wait, the backend limits pinning to 1 *custom* badge. So we can just allow toggling any badge that has a pin.
                    // But if it's auto-pinned, toggling it might show an error.
                    final isAutoPinned = badge['condition_type'] == 'spend';

                    return Card(
                      elevation: isPinned ? 4 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isPinned
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withAlpha(50),
                          width: isPinned ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isPinned)
                              Align(
                                alignment: Alignment.topRight,
                                child: Icon(
                                  Icons.push_pin,
                                  size: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            CachedNetworkImage(
                              imageUrl: ApiService.getImageUrl(
                                badge['icon_url'],
                              ),
                              width: 48,
                              height: 48,
                              errorWidget: (c, u, e) =>
                                  const Icon(Icons.stars, size: 48),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              badge['name'] ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              badge['description'] ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            if (!isAutoPinned)
                              SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: OutlinedButton(
                                  onPressed: _isPinning
                                      ? null
                                      : () =>
                                            _togglePin(ub['id'] ?? badge['id']),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    side: BorderSide(
                                      color: isPinned
                                          ? Colors.red
                                          : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  child: Text(
                                    isPinned ? 'Lepas' : 'Pin',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isPinned
                                          ? Colors.red
                                          : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Auto-Pinned',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
