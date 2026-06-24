import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      String query = '?';
      if (_searchQuery.isNotEmpty) query += 'search=$_searchQuery&';
      if (_roleFilter.isNotEmpty) query += 'role=$_roleFilter&';

      final res = await ApiService.get('${ApiConstants.adminUsers}$query');
      if (res.success && mounted) {
        setState(() {
          _users = res.data['data'] ?? [];
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleStatus(int userId, String newStatus) async {
    try {
      final res = await ApiService.post(ApiConstants.adminUserStatus(userId), body: {'status': newStatus});
      if (res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
        _fetchUsers();
      }
    } catch (_) {}
  }

  void _showBanDialog(int userId, String currentStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(currentStatus == 'banned' ? 'Unban User?' : 'Ban User?'),
        content: Text(currentStatus == 'banned' 
            ? 'User akan bisa menggunakan aplikasi lagi.' 
            : 'User tidak akan bisa login lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _toggleStatus(userId, currentStatus == 'banned' ? 'active' : 'banned');
            },
            style: ElevatedButton.styleFrom(backgroundColor: currentStatus == 'banned' ? Colors.green : Colors.red),
            child: Text(currentStatus == 'banned' ? 'Unban' : 'Ban'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search user...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (val) {
                    setState(() => _searchQuery = val);
                    _fetchUsers();
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _roleFilter.isEmpty ? null : _roleFilter,
                hint: const Text('All Roles'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('All Roles')),
                  DropdownMenuItem(value: 'reader', child: Text('Reader')),
                  DropdownMenuItem(value: 'author', child: Text('Author')),
                ],
                onChanged: (val) {
                  setState(() => _roleFilter = val ?? '');
                  _fetchUsers();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: ListView.separated(
                    itemCount: _users.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final user = _users[i];
                      final isBanned = user['status'] == 'banned';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['avatar_url'] != null
                              ? NetworkImage(ApiService.getImageUrl(user['avatar_url']))
                              : null,
                          child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(user['name'] ?? ''),
                        subtitle: Text('${user['email']} • ${user['role']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isBanned)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(12)),
                                child: const Text('BANNED', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(width: 8),
                            PopupMenuButton(
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'status',
                                  child: Text(isBanned ? 'Unban User' : 'Ban User', style: TextStyle(color: isBanned ? Colors.green : Colors.red)),
                                ),
                              ],
                              onSelected: (val) {
                                if (val == 'status') {
                                  _showBanDialog(user['id'], user['status'] ?? 'active');
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
