import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class ReportDialog {
  static void show(BuildContext context, {required String targetType, required int targetId}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ReportDialogContent(targetType: targetType, targetId: targetId);
      },
    );
  }

  static Widget _buildRadioMenu(String title, String value, String? groupValue, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      // ignore: deprecated_member_use
      groupValue: groupValue,
      // ignore: deprecated_member_use
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ReportDialogContent extends StatefulWidget {
  final String targetType;
  final int targetId;

  const _ReportDialogContent({required this.targetType, required this.targetId});

  @override
  State<_ReportDialogContent> createState() => _ReportDialogContentState();
}

class _ReportDialogContentState extends State<_ReportDialogContent> {
  String? selectedReason;
  final reasonCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (selectedReason == null) return;

    if (selectedReason == 'other' && reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide more details'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final body = {
        'reportable_type': widget.targetType, // e.g. 'user', 'episode', 'series', 'comment'
        'reportable_id': widget.targetId,
        'reason': selectedReason,
      };

      if (selectedReason == 'other') {
        body['description'] = reasonCtrl.text.trim();
      }

      final res = await ApiService.post('reports', body: body);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.success ? 'Report submitted successfully. Thank you!' : 'Failed to submit report.'),
            backgroundColor: res.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Report Content', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this?'),
            const SizedBox(height: 16),
            ReportDialog._buildRadioMenu('Inappropriate Content', 'inappropriate', selectedReason, (val) => setState(() => selectedReason = val)),
            ReportDialog._buildRadioMenu('Spam or Scam', 'spam', selectedReason, (val) => setState(() => selectedReason = val)),
            ReportDialog._buildRadioMenu('Harassment', 'harassment', selectedReason, (val) => setState(() => selectedReason = val)),
            ReportDialog._buildRadioMenu('Intellectual Property Violation', 'copyright', selectedReason, (val) => setState(() => selectedReason = val)),
            ReportDialog._buildRadioMenu('Other', 'other', selectedReason, (val) => setState(() => selectedReason = val)),

            if (selectedReason == 'other') ...[
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Please provide more details...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: (selectedReason != null && !_isSubmitting) ? _submitReport : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSubmitting 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}
