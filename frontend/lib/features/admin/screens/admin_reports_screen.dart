import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
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
      final res = await ApiService.get(ApiConstants.adminReports);
      if (res.success && mounted) {
        setState(() {
          _reports = res.data['data'] ?? [];
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resolveReport(int reportId, String status) async {
    try {
      final res = await ApiService.post(ApiConstants.adminReportResolve(reportId), body: {'status': status});
      if (res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report $status')));
        _fetchReports();
      }
    } catch (_) {}
  }

  void _showActionDialog(int reportId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Take Action'),
        content: const Text('Choose how to resolve this report:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resolveReport(reportId, 'dismissed');
            },
            child: const Text('Dismiss (No Violation)'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resolveReport(reportId, 'resolved');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Resolve Only (Mark Done)'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resolveReport(reportId, 'resolved_delete');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Resolve & Delete Content'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resolveReport(reportId, 'resolved_ban');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Resolve & Ban User'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reports.isEmpty) {
      return const Center(child: Text('No reports found'));
    }

    return RefreshIndicator(
      onRefresh: _fetchReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (ctx, i) {
          final report = _reports[i];
          final reporter = report['reporter'] ?? {};
          final targetType = report['reportable_type']?.toString().split('\\').last ?? 'Unknown';
          final status = report['status'] ?? 'pending';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target: $targetType #${report['reportable_id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'pending' ? Colors.orange[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: status == 'pending' ? Colors.orange[800] : Colors.grey[800],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Reason: ${report['reason']}'),
                  if (report['description'] != null) Text('Detail: ${report['description']}', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Reported by: ${reporter['name']} (${reporter['email']})', style: const TextStyle(fontSize: 12)),
                  Text('Time: ${timeago.format(DateTime.parse(report['created_at']))}', style: const TextStyle(fontSize: 12)),
                  if (status == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _showActionDialog(report['id']),
                          child: const Text('Review Action'),
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
}
