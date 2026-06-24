import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  List<dynamic> _withdrawals = [];
  bool _isLoading = true;

  // Exchange rate: 1 Coin = Rp 80 for Author cashout (80/20 split)
  static const int exchangeRate = 80;
  static const int minWithdrawal = 1000;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(ApiConstants.withdrawals);
      setState(() {
        _withdrawals = response.data?['data'] ?? [];
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  String _formatNumber(dynamic number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  void _showWithdrawDialog() {
    final user = context.read<AuthProvider>().user;
    final coins = user?['coins'] ?? 0;
    final amountController = TextEditingController();
    final bankNameController = TextEditingController();
    final bankAccountController = TextEditingController();
    final bankHolderController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int estimatedIdr = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Tarik Dana', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Saldo tersedia: ${_formatNumber(coins)} Coins', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text('Minimum penarikan: $minWithdrawal Coins', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Kurs: 1 Coin = Rp $exchangeRate (Platform fee 20%)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Coin',
                      hintText: 'Min. $minWithdrawal',
                      prefixIcon: const Icon(Icons.monetization_on),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixText: estimatedIdr > 0 ? '≈ Rp ${_formatNumber(estimatedIdr)}' : null,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      final amount = int.tryParse(v) ?? 0;
                      if (amount < minWithdrawal) return 'Minimum $minWithdrawal Coins';
                      if (amount > coins) return 'Saldo tidak cukup';
                      return null;
                    },
                    onChanged: (v) {
                      final amount = int.tryParse(v) ?? 0;
                      setModalState(() => estimatedIdr = amount * exchangeRate);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: bankNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Bank',
                      hintText: 'BCA, BNI, Mandiri, BRI, dll',
                      prefixIcon: const Icon(Icons.account_balance),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: bankAccountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nomor Rekening',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: bankHolderController,
                    decoration: InputDecoration(
                      labelText: 'Nama Pemilik Rekening',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),

                  if (estimatedIdr > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text('Anda akan menerima', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${_formatNumber(estimatedIdr)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _submitWithdrawal(
                        ctx,
                        formKey,
                        amountController.text,
                        bankNameController.text,
                        bankAccountController.text,
                        bankHolderController.text,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ajukan Penarikan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitWithdrawal(
    BuildContext ctx,
    GlobalKey<FormState> formKey,
    String amount,
    String bankName,
    String bankAccount,
    String bankHolder,
  ) async {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(ctx);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService.post(ApiConstants.withdrawals, body: {
        'amount_coins': int.parse(amount),
        'bank_name': bankName,
        'bank_account_number': bankAccount,
        'bank_account_name': bankHolder,
      });

      if (!mounted) return;
      Navigator.pop(context);

      if (response.success) {
        context.read<AuthProvider>().refreshProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permintaan penarikan berhasil dikirim!'), backgroundColor: Colors.green),
        );
        _loadWithdrawals();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;
    final coins = user?['coins'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Penarikan Dana')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: coins >= minWithdrawal ? _showWithdrawDialog : null,
        backgroundColor: coins >= minWithdrawal ? Colors.green : Colors.grey,
        icon: const Icon(Icons.account_balance_wallet),
        label: const Text('Tarik Dana'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<AuthProvider>().refreshProfile();
                await _loadWithdrawals();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Balance Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
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
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Setara Rp ${_formatNumber(coins * exchangeRate)}',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (coins < minWithdrawal) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Minimum penarikan $minWithdrawal Coins. Kamu butuh ${minWithdrawal - coins} Coins lagi.',
                              style: const TextStyle(color: Colors.orange, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Text('Riwayat Penarikan', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (_withdrawals.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Belum ada riwayat penarikan', style: TextStyle(color: Colors.grey)),
                    ))
                  else
                    ..._withdrawals.map((w) => _buildWithdrawalTile(w)),
                ],
              ),
            ),
    );
  }

  Widget _buildWithdrawalTile(dynamic w) {
    final status = w['status'] ?? '';
    final statusColor = switch (status) {
      'completed' => Colors.green,
      'pending' => Colors.orange,
      'processing' => Colors.blue,
      _ => Colors.red,
    };
    final statusLabel = switch (status) {
      'completed' => 'Selesai',
      'pending' => 'Menunggu',
      'processing' => 'Diproses',
      'rejected' => 'Ditolak',
      _ => status.toString(),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_formatNumber(w['amount_coins'])} Coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Rp ${_formatNumber(w['amount_idr'])}', style: TextStyle(color: Colors.grey[600])),
            Text('${w['bank_name']} - ${w['bank_account_number']}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            if (w['admin_notes'] != null && w['admin_notes'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Note: ${w['admin_notes']}', style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
