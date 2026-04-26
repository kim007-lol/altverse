import 'package:flutter/material.dart';

class ReportDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ReportDialogContent();
      },
    );
  }

  static Widget _buildRadioMenu(String title, String? groupValue, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: title,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ReportDialogContent extends StatefulWidget {
  const _ReportDialogContent();

  @override
  State<_ReportDialogContent> createState() => _ReportDialogContentState();
}

class _ReportDialogContentState extends State<_ReportDialogContent> {
  String? selectedReason;
  final reasonCtrl = TextEditingController();

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
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
            ReportDialog._buildRadioMenu(
              'Inappropriate Content',
              selectedReason,
              (val) => setState(() => selectedReason = val),
            ),
            ReportDialog._buildRadioMenu('Spam or Scam', selectedReason, (val) => setState(() => selectedReason = val)),
            ReportDialog._buildRadioMenu('Harassment', selectedReason, (val) => setState(() => selectedReason = val)),
            ReportDialog._buildRadioMenu(
              'Intellectual Property Violation',
              selectedReason,
              (val) => setState(() => selectedReason = val),
            ),
            ReportDialog._buildRadioMenu('Other', selectedReason, (val) => setState(() => selectedReason = val)),

            if (selectedReason == 'Other') ...[
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: selectedReason != null
              ? () {
                  // Validation
                  if (selectedReason == 'Other' && reasonCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide more details'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Report submitted for review.')));
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Submit Report'),
        ),
      ],
    );
  }
}
