import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get(ApiEndpoints.reports);
      if (res.success && mounted) {
        setState(() => _reports = res.data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteReport(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tarik Report?'),
        content: const Text('Report ini akan ditarik dan dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tarik Report'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.delete(ApiEndpoints.reportDetail(id));
      if (res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report berhasil ditarik')));
        _fetchReports();
      }
    } catch (_) {}
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      return timeago.format(DateTime.parse(dateStr));
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Belum ada report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Report kamu akan muncul di sini', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _reports.length,
                    itemBuilder: (ctx, i) {
                      final report = _reports[i];
                      final status = report['status'] ?? 'pending';
                      final type = report['reportable_type']?.toString().split('\\').last ?? 'Unknown';

                      Color statusColor;
                      String statusText;
                      switch (status) {
                        case 'resolved':
                          statusColor = Colors.green;
                          statusText = 'Selesai';
                          break;
                        case 'dismissed':
                        case 'rejected':
                          statusColor = Colors.red;
                          statusText = 'Ditolak';
                          break;
                        default:
                          statusColor = Colors.orange;
                          statusText = 'Menunggu Review';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withAlpha(40)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (status == 'pending')
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    onPressed: () => _deleteReport(report['id']),
                                    tooltip: 'Tarik Report',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Alasan: ${report['reason'] ?? 'Tidak ada alasan'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (report['details'] != null && report['details'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                report['details'],
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.flag_rounded, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  'Dilaporkan pada konten: $type',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(report['created_at']),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
