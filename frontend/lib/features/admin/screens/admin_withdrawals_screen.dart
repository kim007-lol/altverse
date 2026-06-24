import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class AdminWithdrawalsScreen extends StatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  State<AdminWithdrawalsScreen> createState() => _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends State<AdminWithdrawalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _withdrawals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(ApiConstants.adminWithdrawals);
      if (response.success) {
        setState(() {
          _withdrawals = response.data?['data']?['data'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isLoading = false);
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    return number.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  Future<void> _processWithdrawal(int id, String status, {String? notes}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'completed' ? 'Selesai Transfer?' : 'Tolak Penarikan?'),
        content: Text(status == 'completed' 
          ? 'Pastikan Anda sudah mentransfer uang ke rekening author. Lanjutkan?' 
          : 'Koin akan dikembalikan ke saldo author. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: status == 'completed' ? Colors.green : Colors.red),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post(
        ApiConstants.processWithdrawal(id),
        body: {'status': status, 'admin_notes': notes},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message), backgroundColor: response.success ? Colors.green : Colors.red));
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
      setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog(int id) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Penarikan'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(labelText: 'Alasan Penolakan', hintText: 'Cth: Nomor rekening tidak valid'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processWithdrawal(id, 'rejected', notes: notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak & Refund'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _withdrawals.where((w) => w['status'] == 'pending').toList();
    final history = _withdrawals.where((w) => w['status'] != 'pending').toList();

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Riwayat (${history.length})'),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(pending, true),
                    _buildList(history, false),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildList(List<dynamic> items, bool isPending) {
    if (items.isEmpty) {
      return Center(
        child: Text(isPending ? 'Tidak ada penarikan menunggu.' : 'Belum ada riwayat.'),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final w = items[i];
          final author = w['author'] ?? {};
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(author['name'] ?? 'Unknown Author', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(w['status']).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          w['status']?.toString().toUpperCase() ?? '',
                          style: TextStyle(color: _getStatusColor(w['status']), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildRow('Jumlah Koin', _formatNumber(w['amount_coins'])),
                  _buildRow('Rupiah (IDR)', 'Rp ${_formatNumber(w['amount_idr'])}'),
                  _buildRow('Bank', w['bank_name'] ?? '-'),
                  _buildRow('No. Rekening', w['account_number'] ?? '-'),
                  _buildRow('Nama Rekening', w['account_name'] ?? '-'),
                  if (w['admin_notes'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Catatan Admin: ${w['admin_notes']}', style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
                    ),
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showRejectDialog(w['id']),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Tolak'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _processWithdrawal(w['id'], 'completed'),
                            style: FilledButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Transfer Selesai'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'completed') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }
}
