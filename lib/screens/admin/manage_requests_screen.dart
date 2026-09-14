import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';

/// Admin screen for browsing property requests and moderating their status.
class ManageRequestsScreen extends StatefulWidget {
  const ManageRequestsScreen({super.key});

  static const String routeName = '/admin/requests';

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _requests = const [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final search = _searchController.text.trim();
      final requests = await _service.adminListPropertyRequests(
        statusFilter: _statusFilter == 'all' ? null : _statusFilter,
        searchText: search.isEmpty ? null : search,
      );

      if (!mounted) return;
      setState(() {
        _requests = requests;
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

  Future<void> _changeStatus(
    Map<String, dynamic> request,
    String newStatus,
  ) async {
    final id = request['id'] as String?;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير الحالة'),
        content: Text('تغيير حالة الطلب إلى "$newStatus"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.adminSetPropertyRequestStatus(
        requestId: id,
        status: newStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث الحالة إلى $newStatus.')),
      );
      await _loadRequests();
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
        title: const Text('إدارة الطلبات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
            tooltip: 'تحديث',
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
              onSubmitted: (_) => _loadRequests(),
              decoration: InputDecoration(
                hintText: 'ابحث بعنوان الطلب',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadRequests();
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
                const Text('الحالة:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _statusFilter = value);
                    _loadRequests();
                  },
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('الكل')),
                    DropdownMenuItem(value: 'active', child: Text('نشط')),
                    DropdownMenuItem(value: 'inactive', child: Text('معطّل')),
                    DropdownMenuItem(value: 'sold', child: Text('مباع')),
                    DropdownMenuItem(value: 'rented', child: Text('مؤجَّر')),
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
              onPressed: _loadRequests,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(child: Text('لا توجد طلبات.'));
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.separated(
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = _requests[index];
          final title = (row['title'] as String?) ?? '';
          final status = (row['status'] as String?) ?? '';

          final buyerValue = row['buyer'];
          final buyerName = buyerValue is Map
              ? (buyerValue['full_name'] as String? ?? '—')
              : '—';

          final rawCreatedAt = row['created_at']?.toString() ?? '';
          final createdAt =
              rawCreatedAt.isEmpty ? '' : rawCreatedAt.split('T').first;

          return ListTile(
            title: Text(title),
            subtitle: Text('المشتري: $buyerName\nالحالة: $status\n$createdAt'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              tooltip: 'تغيير الحالة',
              onSelected: (newStatus) => _changeStatus(row, newStatus),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'inactive', child: Text('تعطيل')),
                PopupMenuItem(value: 'active', child: Text('تفعيل')),
              ],
            ),
          );
        },
      ),
    );
  }
}
