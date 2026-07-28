import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'payment_webview_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<dynamic> _packages = [];
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final fallbackPackages = [
      {'id': 'pkg_basic', 'name': 'Basic', 'price_idr': 10000, 'coins': 100, 'bonus': 0},
      {'id': 'pkg_standard', 'name': 'Standard', 'price_idr': 25000, 'coins': 260, 'bonus': 10},
      {'id': 'pkg_premium', 'name': 'Premium', 'price_idr': 50000, 'coins': 550, 'bonus': 50},
      {'id': 'pkg_whale', 'name': 'Whale', 'price_idr': 100000, 'coins': 1150, 'bonus': 150},
    ];

    try {
      final results = await Future.wait([
        ApiService.get(ApiConstants.topupPackages),
        ApiService.get(ApiConstants.topupHistory),
      ]);
      if (!mounted) return;
      setState(() {
        final dataMap = results[0].data as Map<String, dynamic>?;
        final listData = dataMap?['data'] as List?;
        _packages = listData?.isNotEmpty == true ? listData! : fallbackPackages;

        final historyMap = results[1].data as Map<String, dynamic>?;
        _history = historyMap?['data'] ?? [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _packages = fallbackPackages;
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _buyPackage(Map<String, dynamic> pkg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Top-Up'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paket: ${pkg['name']}'),
            const SizedBox(height: 8),
            Text('Harga: Rp ${_formatNumber(pkg['price_idr'])}'),
            Text('Coin: ${pkg['coins']} Coins'),
            if ((pkg['bonus'] ?? 0) > 0)
              Text('Bonus: +${pkg['bonus']} Coins', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Beli Sekarang')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService.post(ApiConstants.topupCreate, body: {
        'package_id': pkg['id'],
      });

      if (!mounted) return;
      Navigator.pop(context); // Remove loading

      if (response.success) {
        final orderId = response.data?['order_id'] as String?;
        final redirectUrl = response.data?['redirect_url'] as String?;
        
        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          // Open in-app WebView for payment
          final didPay = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentWebViewScreen(
                redirectUrl: redirectUrl,
                orderId: orderId ?? '-',
              ),
            ),
          );

          if (didPay == true && mounted) {
            _checkPaymentAndRefresh(orderId);
          }
        } else {
          // Midtrans not configured — testing mode
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mode Testing (Midtrans belum dikonfigurasi)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


  Future<void> _checkPaymentAndRefresh(String? orderId) async {
    if (orderId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService.post(ApiConstants.topupCheckStatus, body: {
        'order_id': orderId,
      });

      if (!mounted) return;
      Navigator.pop(context);

      final status = response.data?['status'];
      if (status == 'paid') {
        context.read<AuthProvider>().refreshProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran berhasil! Coin telah ditambahkan.'), backgroundColor: Colors.green),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status pembayaran: $status. Menunggu konfirmasi...'), backgroundColor: Colors.orange),
        );
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  String _formatNumber(dynamic number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;
    final coins = user?['coins'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<AuthProvider>().refreshProfile();
                await _loadData();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Coin Balance Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo Coin', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 36),
                            const SizedBox(width: 12),
                            Text(
                              _formatNumber(coins),
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Text('Coins', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Top-Up Packages ──
                  Text('Top-Up Coin', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Pembayaran via QRIS (Midtrans)', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ..._packages.map((pkg) => _buildPackageCard(pkg)),

                  const SizedBox(height: 24),

                  // ── Transaction History ──
                  Text('Riwayat Top-Up', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_history.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Belum ada riwayat top-up', style: TextStyle(color: Colors.grey)),
                    ))
                  else
                    ..._history.map((h) => _buildHistoryTile(h)),
                ],
              ),
            ),
    );
  }

  Widget _buildPackageCard(dynamic pkg) {
    final bonus = pkg['bonus'] ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _buyPackage(Map<String, dynamic>.from(pkg)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pkg['coins']} Coins',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (bonus > 0)
                      Text('+$bonus bonus', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Rp ${_formatNumber(pkg['price_idr'])}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(dynamic h) {
    final status = h['status'] ?? '';
    final statusColor = status == 'paid' ? Colors.green : (status == 'pending' ? Colors.orange : Colors.red);
    final statusLabel = status == 'paid' ? 'Berhasil' : (status == 'pending' ? 'Menunggu' : status.toString().toUpperCase());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          status == 'paid' ? Icons.check_circle : Icons.pending,
          color: statusColor,
        ),
        title: Text('${h['coins']} Coins'),
        subtitle: Text('Rp ${_formatNumber(h['amount_idr'])}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}
