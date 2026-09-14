import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';

/// Admin screen for browsing the audit log.
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  static const String routeName = '/admin/audit-log';

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final SupabaseService _service = SupabaseService();

  List<Map<String, dynamic>> _logs = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await _service.adminGetAuditLogs();

      if (!mounted) return;
      setState(() {
        _logs = logs;
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

  String _formatTimestamp(dynamic value) {
    if (value == null) return '';
    try {
      final parsed = DateTime.parse(value as String).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm', 'en_US').format(parsed);
    } catch (_) {
      return value.toString();
    }
  }

  String _actorName(Map<String, dynamic> row) {
    final actor = row['actor'];
    if (actor is Map) {
      final name = actor['full_name'];
      if (name is String && name.isNotEmpty) return name;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
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
              onPressed: _loadLogs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_logs.isEmpty) {
      return const Center(child: Text('No audit log entries.'));
    }

    return RefreshIndicator(
      onRefresh: _loadLogs,
      child: ListView.separated(
        itemCount: _logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = _logs[index];
          final action = (row['action'] as String?) ?? '';
          final entityType = (row['entity_type'] as String?) ?? '';
          final entityId = row['entity_id']?.toString() ?? '—';
          final actor = _actorName(row);
          final timestamp = _formatTimestamp(row['created_at']);

          return ListTile(
            title: Text(action),
            subtitle: Text('$entityType: $entityId · $actor · $timestamp'),
          );
        },
      ),
    );
  }
}
