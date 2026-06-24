import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  List<dynamic> _settings = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get(ApiConstants.adminSettings);
      if (res.success && mounted) {
        setState(() {
          _settings = res.data;
          for (var s in _settings) {
            final key = s['key'];
            if (!_controllers.containsKey(key)) {
              _controllers[key] = TextEditingController(text: s['value'] ?? '');
            } else {
              _controllers[key]!.text = s['value'] ?? '';
            }
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final updatedSettings = _controllers.entries.map((e) {
        return {'key': e.key, 'value': e.value.text};
      }).toList();

      final res = await ApiService.put(ApiConstants.adminSettings, body: {'settings': updatedSettings});
      if (res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save settings'), backgroundColor: Colors.red));
      }
    } catch (_) {}
    if (mounted) setState(() => _isSaving = false);
  }

  void _addNewSetting() {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Setting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'Key (e.g. coin_price)')),
            TextField(controller: valCtrl, decoration: const InputDecoration(labelText: 'Value')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (keyCtrl.text.isNotEmpty) {
                setState(() {
                  _controllers[keyCtrl.text] = valCtrl;
                  _settings.add({'key': keyCtrl.text, 'value': valCtrl.text});
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('System Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addNewSetting,
                icon: const Icon(Icons.add),
                label: const Text('Add Variable'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _settings.length,
            itemBuilder: (ctx, i) {
              final s = _settings[i];
              final key = s['key'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                  controller: _controllers[key],
                  decoration: InputDecoration(
                    labelText: key,
                    border: const OutlineInputBorder(),
                    helperText: s['description'] ?? 'System configuration for $key',
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'),
          ),
        ),
      ],
    );
  }
}
