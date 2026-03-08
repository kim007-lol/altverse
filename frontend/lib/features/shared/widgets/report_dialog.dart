import 'package:flutter/material.dart';

class ReportDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedReason;
        final reasonCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Report Content',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Why are you reporting this?'),
                    const SizedBox(height: 16),
                    _buildRadioMenu(
                      'Inappropriate Content',
                      selectedReason,
                      (val) => setState(() => selectedReason = val),
                    ),
                    _buildRadioMenu(
                      'Spam or Scam',
                      selectedReason,
                      (val) => setState(() => selectedReason = val),
                    ),
                    _buildRadioMenu(
                      'Harassment',
                      selectedReason,
                      (val) => setState(() => selectedReason = val),
                    ),
                    _buildRadioMenu(
                      'Intellectual Property Violation',
                      selectedReason,
                      (val) => setState(() => selectedReason = val),
                    ),
                    _buildRadioMenu(
                      'Other',
                      selectedReason,
                      (val) => setState(() => selectedReason = val),
                    ),

                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: reasonCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Please provide more details...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedReason != null
                      ? () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report submitted for review.'),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Submit Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildRadioMenu(
    String title,
    String? groupValue,
    ValueChanged<String?> onChanged,
  ) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: title,
      // ignore: deprecated_member_use
      groupValue: groupValue,
      // ignore: deprecated_member_use
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
