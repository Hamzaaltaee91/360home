import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';

/// Admin screen for browsing the user directory and moderating roles.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  static const String routeName = '/admin/users';

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<AppUser> _users = const [];
  bool _isLoading = true;
  String? _error;
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final search = _searchController.text.trim();
      final users = await _service.listUsers(
        role: _roleFilter == 'all' ? null : _roleFilter,
        search: search.isEmpty ? null : search,
      );

      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = SupabaseErrorHandler.handle(e).message;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeRole(AppUser user, String newRole) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change role'),
        content: Text(
          'Change ${user.fullName}\'s role to "$newRole"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.updateUserRole(userId: user.id, role: newRole);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.fullName} is now a $newRole.')),
      );
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SupabaseErrorHandler.handle(e).message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadUsers(),
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadUsers();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Role:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _roleFilter,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _roleFilter = value);
                    _loadUsers();
                  },
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'buyer', child: Text('Buyers')),
                    DropdownMenuItem(value: 'realtor', child: Text('Realtors')),
                    DropdownMenuItem(value: 'admin', child: Text('Admins')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.profilePictureUrl != null
                  ? NetworkImage(user.profilePictureUrl!)
                  : null,
              child: user.profilePictureUrl == null
                  ? Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            title: Text(user.fullName),
            subtitle: Text('${user.email}\nRole: ${user.role}'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              tooltip: 'Change role',
              onSelected: (role) => _changeRole(user, role),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'buyer', child: Text('Make buyer')),
                PopupMenuItem(value: 'realtor', child: Text('Make realtor')),
                PopupMenuItem(value: 'admin', child: Text('Make admin')),
              ],
            ),
          );
        },
      ),
    );
  }
}
