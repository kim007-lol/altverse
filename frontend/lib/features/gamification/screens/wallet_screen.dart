import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic> _data = {};
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    try {
      final res = await ApiService.get(ApiEndpoints.wallet);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _data = json;
            _transactions =
                (json['transactions']?['data'] ?? json['transactions'] ?? [])
                    as List;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coins = _data['coins'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Balance Card ───
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withAlpha(180),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 32,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatNumber(coins),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Coins',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Level ${_data['level'] ?? 1} • ${_data['exp_points'] ?? 0} XP',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Transaction History ───
                    const Text(
                      'Transaction History',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada transaksi',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._transactions.map((tx) => _buildTxTile(tx, theme)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTxTile(dynamic tx, ThemeData theme) {
    final amount = (tx['amount'] as num?)?.toInt() ?? 0;
    final isIncome = amount > 0;
    final type = tx['type'] ?? '';
    final desc = tx['description'] ?? type;
    final date = tx['created_at'] ?? '';

    String formattedDate = date;
    try {
      final dt = DateTime.parse(date);
      formattedDate =
          '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isIncome ? Colors.green : Colors.red).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : ''}$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic n) {
    final num val = n is num ? n : 0;
    if (val >= 1000) {
      return val.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return val.toInt().toString();
  }
}
